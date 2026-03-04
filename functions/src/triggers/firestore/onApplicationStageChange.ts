import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { Application } from "../../types/models";
// Importamos la función de auditoría si existe, de lo contrario la omitimos o creamos un log nativo.

export const onApplicationStageChange = onDocumentUpdated(
  "applications/{applicationId}",
  async (event) => {
    const beforeData = event.data?.before.data() as Application | undefined;
    const afterData = event.data?.after.data() as Application | undefined;

    if (!beforeData || !afterData) return;

    // Detectamos si cambió la etapa (pipelineStageId) o el status general a rejected/hired
    const stageChanged = beforeData.pipelineStageId !== afterData.pipelineStageId;
    const statusChanged = beforeData.status !== afterData.status;

    if (!stageChanged && !statusChanged) {
      return;
    }

    // Aquí irían las implementaciones de notificaciones push / emails.
    // Ej:
    // await sendEmailToCandidate({
    //   to: afterData.candidate_email,
    //   template: 'application_status_changed',
    //   data: { offerId: afterData.job_offer_id, newStage: afterData.pipelineStageName }
    // });
    
    console.log(`[ATS Notifier] Application ${event.params.applicationId} stage/status changed. Candidate: ${afterData.candidate_uid}, New Stage: ${afterData.pipelineStageName}, Status: ${afterData.status}`);
  }
);
