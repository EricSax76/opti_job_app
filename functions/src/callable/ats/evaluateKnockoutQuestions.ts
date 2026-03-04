import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Application, JobOffer, KnockoutQuestion } from "../../types/models";

/**
 * Función Callable que recibe las respuestas de un candidato a las preguntas eliminatorias.
 * Si alguna respuesta requerida no coincide, el candidato debe moverse a una etapa "rejected" o flaggearse.
 */
export const evaluateKnockoutQuestions = onCall(async (request) => {
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

      const updateData: Partial<Application> = {
        knockoutResponses: responses,
        updated_at: FieldValue.serverTimestamp() as unknown as Application["updated_at"],
      };

      let statusMsg = "Knockout questions evaluated successfully.";

      // Si falla las preguntas eliminatorias, se puede mover de pipelineStage o poner status = rejected
      // Dependerá de la implementación exacta, asumiendo stage "rejected"
      if (failedKnockout) {
        // En una app real podríamos buscar dinámicamente el StageType "rejected"
        const rejectedStageId = offerData.pipelineStages?.find(s => s.type === "rejected")?.id;
        if (rejectedStageId) {
          updateData.pipelineStageId = rejectedStageId;
          updateData.pipelineStageName = "Descartado";
          const now = new Date().toISOString();
          updateData.pipelineHistory = FieldValue.arrayUnion({
            stageId: rejectedStageId,
            stageName: "Descartado (Auto-filtro)",
            movedBy: "system",
            movedAt: now,
          }) as unknown as Application["pipelineHistory"];
          
          updateData.status = "rejected";
        }
        statusMsg = "Knockout questions failed. Application marked as rejected.";
      }

      transaction.update(applicationRef, updateData);

      return {
        success: true,
        knockoutPassed: !failedKnockout,
        message: statusMsg,
      };
    });

    return result;
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("Error evaluating knockout questions:", error);
    throw new HttpsError("internal", "Internal server error estimating knockout logic.", error);
  }
});
