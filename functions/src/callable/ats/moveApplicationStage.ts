import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { PipelineStage } from "../../types/pipeline";

/** Stage types that trigger identity reveal (LGPD blind review). */
const REVEAL_STAGE_TYPES = new Set<string>(["interview", "offer", "hired"]);

export const moveApplicationStage = onCall({ region: "europe-west1", memory: "256MiB" }, async (request) => {
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

      const data = doc.data()!;
      const companyUid = data.company_uid;
      const currentStageId = data.pipelineStageId;
      const jobOfferId = String(
        data.job_offer_id ?? data.jobOfferId ?? ""
      ).trim();

      // Verificación de acceso
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
        if (!["admin", "recruiter"].includes(String(recruiterData?.role ?? ""))) {
          throw new HttpsError("permission-denied", "Tu rol no tiene permiso para cambiar etapas.");
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

      const updateData: Record<string, unknown> = {
        pipelineStageId: newStageId,
        pipelineStageName: newStageName,
        updated_at: FieldValue.serverTimestamp(),
        pipelineHistory: FieldValue.arrayUnion(historyEntry),
      };

      // ── LGPD blind review: resolve stage type and mark reveal ───
      if (jobOfferId && data.identityRevealed !== true) {
        const offerDoc = await transaction.get(
          db.collection("jobOffers").doc(jobOfferId)
        );
        const stages =
          (offerDoc.data()?.pipelineStages as PipelineStage[] | undefined) ??
          [];
        const newStage = stages.find((s) => s.id === newStageId);
        const newStageType = newStage?.type ?? "";

        if (REVEAL_STAGE_TYPES.has(newStageType)) {
          updateData.identityRevealed = true;
          updateData.identityRevealedAt = FieldValue.serverTimestamp();
          updateData.identityRevealedBy = request.auth?.uid;
        }
      }

      transaction.update(applicationRef, updateData);

      return { success: true };
    });

    return result;
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("Error moviendo candidato:", error);
    throw new HttpsError("internal", "Error interno al mover candidato de etapa.");
  }
});
