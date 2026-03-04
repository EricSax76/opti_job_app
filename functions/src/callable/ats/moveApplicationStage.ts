import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

export const moveApplicationStage = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const { applicationId, newStageId, newStageName } = request.data as {
    applicationId?: string;
    newStageId?: string;
    newStageName?: string;
  };

  if (!applicationId || !newStageId || !newStageName) {
    throw new HttpsError("invalid-argument", "Faltan parámetros requeridos.");
  }

  const db = getFirestore();
  const applicationRef = db.collection("applications").doc(applicationId);

  try {
    const result = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(applicationRef);
      if (!doc.exists) {
        throw new HttpsError("not-found", "Postulación no encontrada.");
      }

      const data = doc.data();
      const companyUid = data?.company_uid;
      const currentStageId = data?.pipelineStageId;

      // Verificación de acceso
      // Quien mueve la oferta debe ser la empresa o un reclutador con permisos de su empresa (rol admin / recruiter)
      const isCompanyMainAccount = request.auth?.uid === companyUid;

      if (!isCompanyMainAccount) {
        const recruiterRef = db.collection("recruiters").doc(request.auth?.uid || "");
        const recruiterDoc = await transaction.get(recruiterRef);
        if (!recruiterDoc.exists) {
          throw new HttpsError("permission-denied", "No tienes acceso a esta postulación.");
        }
        const recruiterData = recruiterDoc.data();
        if (recruiterData?.companyId !== companyUid || recruiterData?.status !== "active") {
          throw new HttpsError("permission-denied", "No tienes acceso a esta postulación.");
        }
        // Solo un viewer no puede mover la card.
        if (recruiterData?.role === "viewer") {
          throw new HttpsError("permission-denied", "Los visores no pueden cambiar etapas.");
        }
      }

      // Evita actualizar si ya está en esta stage.
      if (currentStageId === newStageId) {
        return { success: true, message: "La postulación ya se encuentra en esta etapa." };
      }

      const now = new Date().toISOString();
      const historyEntry = {
        stageId: newStageId,
        stageName: newStageName,
        movedBy: request.auth?.uid,
        movedAt: now,
      };

      transaction.update(applicationRef, {
        pipelineStageId: newStageId,
        pipelineStageName: newStageName,
        updated_at: FieldValue.serverTimestamp(),
        pipelineHistory: FieldValue.arrayUnion(historyEntry),
      });

      return { success: true };
    });

    return result;
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("Error moviendo candidato:", error);
    throw new HttpsError("internal", "Error interno al mover candadito de etapa.", error);
  }
});
