import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Application, JobOffer, KnockoutQuestion } from "../../types/models";
import {
  grantedAtMillis,
  hasValidAiConsentRecord,
} from "../../utils/aiConsent";
import { writeAuditLog } from "../../utils/auditLog";
import { ensureCallableResponseContract } from "../../utils/contractConventions";
import { resolveOfferPipelineStages } from "./utils/pipelineStages";

async function hasValidAiTestConsent({
  transaction,
  db,
  candidateUid,
  companyId,
}: {
  transaction: FirebaseFirestore.Transaction;
  db: FirebaseFirestore.Firestore;
  candidateUid: string;
  companyId: string;
}): Promise<boolean> {
  const snapshot = await transaction.get(
    db.collection("consentRecords").where("candidateUid", "==", candidateUid).limit(50),
  );
  if (snapshot.empty) return false;

  const now = new Date();
  const records = snapshot.docs
    .map((doc) => doc.data() as Record<string, unknown>)
    .sort((a, b) => grantedAtMillis(b) - grantedAtMillis(a));

  return records.some((record) =>
    hasValidAiConsentRecord({
      record,
      companyId,
      requiredScope: "ai_test",
      now,
    }),
  );
}

function resolveErrorCode(error: unknown): string {
  if (error instanceof HttpsError) return error.code;
  return "internal";
}

function resolveErrorMessage(error: unknown): string {
  if (error instanceof HttpsError) return String(error.message ?? "Unknown error");
  if (error instanceof Error) return error.message;
  return String(error ?? "Unknown error");
}

async function recordKnockoutEvaluationFailure({
  db,
  applicationId,
  actorUid,
  error,
  responses,
}: {
  db: FirebaseFirestore.Firestore;
  applicationId: string;
  actorUid: string;
  error: unknown;
  responses: Record<string, string | boolean> | undefined;
}): Promise<void> {
  if (!applicationId) return;

  const errorCode = resolveErrorCode(error);
  const errorMessage = resolveErrorMessage(error);
  const now = FieldValue.serverTimestamp();
  const appRef = db.collection("applications").doc(applicationId);
  let applicationSignalWritten = false;

  try {
    const appSnap = await appRef.get();
    if (appSnap.exists) {
      const appData = appSnap.data() as Application;
      const candidateUid = String(appData.candidate_uid ?? "").trim();
      if (candidateUid && candidateUid === actorUid) {
        await appRef.update({
          knockoutEvaluationStatus: "failed",
          knockoutEvaluationNeedsAttention: true,
          knockoutEvaluationLastErrorCode: errorCode,
          knockoutEvaluationLastErrorMessage: errorMessage,
          knockoutEvaluationLastAttemptAt: now,
          knockoutEvaluationAttempts: FieldValue.increment(1),
          requiresHumanReview: true,
          updated_at: now,
          updatedAt: now,
        });
        applicationSignalWritten = true;
      }
    }

    await writeAuditLog({
      action: "knockout_evaluation_failed",
      actorUid,
      actorRole: "candidate",
      targetType: "application",
      targetId: applicationId,
      metadata: {
        errorCode,
        errorMessage,
        responsesCount: Object.keys(responses ?? {}).length,
        applicationSignalWritten,
      },
    });
  } catch (persistError) {
    console.error("Failed to persist knockout failure signal:", persistError);
  }
}

/**
 * Evalúa respuestas de knockout sin realizar rechazo totalmente automatizado.
 * Si falla un criterio, la candidatura queda marcada para revisión humana.
 */
export const evaluateKnockoutQuestions = onCall({ region: "europe-west1", memory: "256MiB" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión para postularte.");
  }

  const { applicationId, responses } = request.data as {
    applicationId?: string;
    responses?: Record<string, string | boolean>;
  };

  if (!applicationId || !responses) {
    throw new HttpsError("invalid-argument", "applicationId and responses are required.");
  }

  const db = getFirestore();
  const applicationRef = db.collection("applications").doc(applicationId);

  try {
    const result = await db.runTransaction(async (transaction) => {
      const appDoc = await transaction.get(applicationRef);
      if (!appDoc.exists) {
        throw new HttpsError("not-found", "Application not found.");
      }

      const appData = appDoc.data() as Application;
      if (appData.candidate_uid !== request.auth?.uid) {
        throw new HttpsError("permission-denied", "You can only answer questions for your own application.");
      }

      const offerRef = db.collection("jobOffers").doc(appData.job_offer_id);
      const offerDoc = await transaction.get(offerRef);
      if (!offerDoc.exists) {
        throw new HttpsError("not-found", "Job offer not found.");
      }

      const offerData = offerDoc.data() as JobOffer;
      const pipelineStages = await resolveOfferPipelineStages({
        db,
        transaction,
        offerData: (offerDoc.data() ?? {}) as Record<string, unknown>,
      });
      const offerCompanyUid = String(
        (offerData as unknown as Record<string, unknown>).company_uid ??
          (offerData as unknown as Record<string, unknown>).companyUid ??
          (offerData as unknown as Record<string, unknown>).owner_uid ??
          "",
      ).trim();
      if (!offerCompanyUid) {
        throw new HttpsError(
          "failed-precondition",
          "Job offer does not include company owner.",
        );
      }

      const hasConsent = await hasValidAiTestConsent({
        transaction,
        db,
        candidateUid: appData.candidate_uid,
        companyId: offerCompanyUid,
      });
      if (!hasConsent) {
        transaction.update(applicationRef, {
          aiConsentRequired: true,
          aiConsentScopeRequired: "ai_test",
          aiConsentStatus: "missing_or_invalid",
          aiConsentBlockedAt: FieldValue.serverTimestamp(),
          requiresHumanReview: true,
          knockoutEvaluationStatus: "blocked_consent",
          knockoutEvaluationNeedsAttention: true,
          knockoutEvaluationLastErrorCode: null,
          knockoutEvaluationLastErrorMessage: null,
          knockoutEvaluationLastAttemptAt: FieldValue.serverTimestamp(),
          knockoutEvaluationAttempts: FieldValue.increment(1),
          updated_at: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return ensureCallableResponseContract(
          {
            success: false,
            consentRequired: true,
            requiredScope: "ai_test",
            message: "No AI test consent found for this application.",
          },
          { callableName: "evaluateKnockoutQuestions" },
        );
      }

      const questions: KnockoutQuestion[] = offerData.knockoutQuestions || [];

      let failedKnockout = false;

      // Evaluamos cada pregunta que tenga un 'requiredAnswer' configurado
      for (const question of questions) {
        if (question.requiredAnswer !== undefined && question.requiredAnswer !== null) {
          const candidateAnswer = responses[question.id];
          
          if (question.type === "boolean") {
            // Comparación estricta de booleanos
            if (candidateAnswer !== question.requiredAnswer) {
              failedKnockout = true;
              break;
            }
          } else {
            // Comparación string (opciones) ignorando case y espacios
            const req = String(question.requiredAnswer).trim().toLowerCase();
            const ans = String(candidateAnswer || "").trim().toLowerCase();
            if (req !== ans) {
              failedKnockout = true;
              break;
            }
          }
        }
      }

      const updateData: Record<string, unknown> = {
        knockoutResponses: responses,
        knockoutPassed: !failedKnockout,
        requiresHumanReview: failedKnockout,
        aiConsentRequired: false,
        aiConsentStatus: "granted",
        aiConsentBlockedAt: null,
        knockoutEvaluationStatus: "completed",
        knockoutEvaluationNeedsAttention: false,
        knockoutEvaluationLastErrorCode: null,
        knockoutEvaluationLastErrorMessage: null,
        knockoutEvaluationLastAttemptAt: FieldValue.serverTimestamp(),
        knockoutEvaluationAttempts: FieldValue.increment(1),
        updated_at: FieldValue.serverTimestamp() as unknown as Application["updated_at"],
        updatedAt: FieldValue.serverTimestamp() as unknown as Application["updated_at"],
      };

      let statusMsg = "Knockout questions evaluated successfully.";

      // AI Act: no se permite rechazo totalmente automatizado sin validación humana.
      // Si falla el knockout, se marca para revisión y (si existe) se mueve a etapa screening.
      if (failedKnockout) {
        const screeningStage = pipelineStages.find(
          (s) => s.type === "screening"
        );
        if (screeningStage) {
          updateData.pipelineStageId = screeningStage.id;
          updateData.pipelineStageName = screeningStage.name;
          const now = new Date().toISOString();
          updateData.pipelineHistory = FieldValue.arrayUnion({
            stageId: screeningStage.id,
            stageName: `${screeningStage.name} (Revisión humana requerida)`,
            movedBy: "system",
            movedAt: now,
          }) as unknown as Application["pipelineHistory"];
        }
        updateData.status = "reviewing";
        statusMsg = "Knockout failed. Application flagged for human review.";
      }

      transaction.update(applicationRef, updateData);

      return ensureCallableResponseContract(
        {
          success: true,
          knockoutPassed: !failedKnockout,
          message: statusMsg,
        },
        { callableName: "evaluateKnockoutQuestions" },
      );
    });

    return ensureCallableResponseContract(result, {
      callableName: "evaluateKnockoutQuestions",
    });
  } catch (error) {
    await recordKnockoutEvaluationFailure({
      db,
      applicationId: applicationId || "",
      actorUid: request.auth?.uid ?? "unknown",
      error,
      responses,
    });

    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("Error evaluating knockout questions:", error);
    throw new HttpsError("internal", "Internal server error estimating knockout logic.", error);
  }
});
