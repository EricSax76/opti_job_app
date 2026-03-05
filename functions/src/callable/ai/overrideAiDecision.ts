import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { writeAiDecisionLog, writeAuditLog } from "../../utils/aiDecisionLogs";

type JsonRecord = Record<string, unknown>;

const ALLOWED_OVERRIDE_ROLES = new Set(["admin", "recruiter", "hiring_manager"]);

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

function asNullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return null;
  return parsed;
}

function randomId(prefix: string): string {
  const random = Math.random().toString(16).slice(2, 10);
  return `${prefix}_${Date.now()}_${random}`;
}

async function assertCanOverride({
  db,
  actorUid,
  companyId,
}: {
  db: FirebaseFirestore.Firestore;
  actorUid: string;
  companyId: string;
}): Promise<"company" | "recruiter"> {
  if (actorUid === companyId) return "company";

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Solo la empresa o recruiters autorizados pueden aplicar override.",
    );
  }
  const recruiter = asRecord(recruiterDoc.data());
  const recruiterCompanyId = asTrimmedString(recruiter.companyId);
  const recruiterStatus = asTrimmedString(recruiter.status).toLowerCase();
  const recruiterRole = asTrimmedString(recruiter.role);

  if (
    recruiterCompanyId !== companyId ||
    recruiterStatus !== "active" ||
    !ALLOWED_OVERRIDE_ROLES.has(recruiterRole)
  ) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Tu rol no tiene permisos para sobrescribir decisiones IA en esta empresa.",
    );
  }
  return "recruiter";
}

export const overrideAiDecision = functions.region("europe-west1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const applicationId = asTrimmedString(data?.applicationId);
  const reason = asTrimmedString(data?.reason);
  const requestId = asTrimmedString(data?.requestId) || randomId("req");
  const executionId = randomId("exec");

  if (!applicationId || !reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "applicationId and reason are required.",
    );
  }

  const db = admin.firestore();
  const appRef = db.collection("applications").doc(applicationId);
  const appDoc = await appRef.get();
  if (!appDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Application not found.");
  }
  const appData = asRecord(appDoc.data());
  const companyId =
    asTrimmedString(appData.company_uid) ||
    asTrimmedString(appData.companyUid);
  const candidateUid =
    asTrimmedString(appData.candidate_uid) ||
    asTrimmedString(appData.candidateId);
  const jobOfferId =
    asTrimmedString(appData.job_offer_id) ||
    asTrimmedString(appData.jobOfferId);

  if (!companyId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Application does not have a resolvable company.",
    );
  }

  const actorScope = await assertCanOverride({
    db,
    actorUid: context.auth.uid,
    companyId,
  });

  const aiMatchResult = asRecord(appData.aiMatchResult);
  const scoreFromPayload = asNullableNumber(data?.originalAiScore);
  const currentScore =
    scoreFromPayload ??
    asNullableNumber(appData.match_score) ??
    asNullableNumber(aiMatchResult.score) ??
    0;
  const overrideScore = asNullableNumber(data?.overrideScore);
  const finalScore = overrideScore ?? currentScore;
  const weightsRaw = asRecord(aiMatchResult.weights);

  await appRef.set({
    humanOverride: {
      overriddenBy: context.auth.uid,
      overriddenAt: admin.firestore.FieldValue.serverTimestamp(),
      originalAiScore: currentScore,
      overrideScore: finalScore,
      reason,
      requestId,
      executionId,
    },
    aiMatchResult: {
      reviewedByHuman: true,
      reviewStatus: "overridden",
      override: {
        reason,
        overriddenBy: context.auth.uid,
        overriddenAt: admin.firestore.FieldValue.serverTimestamp(),
        previousScore: currentScore,
        overrideScore: finalScore,
      },
    },
    match_score: finalScore,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  const decisionLogId = await writeAiDecisionLog({
    applicationId,
    companyId,
    candidateUid,
    jobOfferId,
    decisionType: "human_override",
    decisionStatus: "overridden",
    previousScore: currentScore,
    score: finalScore,
    weights: {
      semanticWeight: asNullableNumber(weightsRaw.semanticWeight) ?? undefined,
      skillsWeight: asNullableNumber(weightsRaw.skillsWeight) ?? undefined,
      locationWeight: asNullableNumber(weightsRaw.locationWeight) ?? undefined,
      experienceWeight: asNullableNumber(weightsRaw.experienceWeight) ?? undefined,
    },
    model: {
      provider: asTrimmedString(asRecord(aiMatchResult.model).provider) || "unknown",
      model:
        asTrimmedString(asRecord(aiMatchResult.model).embeddingModel) ||
        asTrimmedString(aiMatchResult.modelVersion) ||
        "unknown",
      version: "v1",
      source: "human_override",
    },
    requestId,
    executionId,
    features: {
      reason,
      previousAiResult: aiMatchResult,
      overrideRequestedScore: overrideScore,
    },
    metadata: {
      overrideBy: context.auth.uid,
      actorScope,
    },
    actorUid: context.auth.uid,
    actorRole: actorScope,
  });

  await writeAuditLog({
    action: "ai_decision_overridden",
    actorUid: context.auth.uid,
    actorRole: actorScope,
    targetType: "application",
    targetId: applicationId,
    companyId,
    metadata: {
      requestId,
      executionId,
      decisionLogId,
      originalAiScore: currentScore,
      overrideScore: finalScore,
      reason,
    },
  });

  return {
    success: true,
    applicationId,
    decisionLogId,
    originalAiScore: currentScore,
    overrideScore: finalScore,
  };
});
