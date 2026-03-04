import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { Application } from "../../types/models";

type JsonRecord = Record<string, unknown>;

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

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asTrimmedString(item))
    .filter((item) => item.length > 0);
}

function normalizeStatus(value: unknown): string {
  return asTrimmedString(value).toLowerCase();
}

interface FeedbackPayload {
  title: string;
  message: string;
  actions: string[];
  trigger: "status_changed" | "stage_changed";
}

function dedupe(values: string[]): string[] {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

function deriveActions(afterData: Application): string[] {
  const aiMatchResult = asRecord((afterData as unknown as JsonRecord).aiMatchResult);
  const overlap = asRecord(aiMatchResult.skillsOverlap);

  const recommendations = asStringList(aiMatchResult.recommendations).slice(0, 2);
  const missingSkills = asStringList(overlap.missing)
    .slice(0, 2)
    .map((skill) => `Refuerza la skill "${skill}" para próximos procesos.`);
  const reasons = asStringList(aiMatchResult.reasons)
    .slice(0, 1)
    .map((reason) => `Considera mejorar: ${reason}`);

  const actions = dedupe([
    ...recommendations,
    ...missingSkills,
    ...reasons,
    "Actualiza tu CV y portfolio con resultados medibles recientes.",
  ]);

  return actions.slice(0, 4);
}

function buildFeedback({
  beforeData,
  afterData,
  stageChanged,
  statusChanged,
}: {
  beforeData: Application;
  afterData: Application;
  stageChanged: boolean;
  statusChanged: boolean;
}): FeedbackPayload {
  const nextStatus = normalizeStatus(afterData.status);
  const previousStatus = normalizeStatus(beforeData.status);
  const nextStage = asTrimmedString(afterData.pipelineStageName);
  const previousStage = asTrimmedString(beforeData.pipelineStageName);
  const actions = deriveActions(afterData);

  if (statusChanged) {
    if (nextStatus === "rejected") {
      return {
        trigger: "status_changed",
        title: "Actualización de candidatura",
        message:
          "La candidatura se ha cerrado en esta vacante. Puedes usar este feedback para mejorar tu próximo match.",
        actions,
      };
    }
    if (nextStatus === "interviewing") {
      return {
        trigger: "status_changed",
        title: "Avance a entrevista",
        message:
          "Tu candidatura avanzó a fase de entrevista. Revisa estos puntos para preparar respuestas concretas.",
        actions,
      };
    }
    if (nextStatus === "offered") {
      return {
        trigger: "status_changed",
        title: "Estás en fase de oferta",
        message:
          "Has llegado a oferta final. Verifica condiciones económicas y alcance técnico antes de aceptar.",
        actions,
      };
    }
    if (nextStatus === "hired") {
      return {
        trigger: "status_changed",
        title: "Candidatura completada",
        message:
          "La candidatura se marcó como contratada. Enhorabuena, conserva este histórico como referencia.",
        actions,
      };
    }
    if (nextStatus === "reviewing" || nextStatus === "pending") {
      return {
        trigger: "status_changed",
        title: "Candidatura en revisión",
        message:
          "Tu candidatura está en revisión. Mientras tanto, puedes reforzar skills clave para mejorar afinidad.",
        actions,
      };
    }

    return {
      trigger: "status_changed",
      title: "Cambio de estado de candidatura",
      message: `Estado actualizado de "${previousStatus || "desconocido"}" a "${nextStatus || "desconocido"}".`,
      actions,
    };
  }

  return {
    trigger: "stage_changed",
    title: "Movimiento en pipeline",
    message: `Tu candidatura pasó de "${previousStage || "etapa inicial"}" a "${nextStage || "siguiente etapa"}".`,
    actions,
  };
}

export const onApplicationStageChange = onDocumentUpdated(
  "applications/{applicationId}",
  async (event) => {
    const beforeData = event.data?.before.data() as Application | undefined;
    const afterData = event.data?.after.data() as Application | undefined;
    if (!beforeData || !afterData) return;

    const stageChanged = beforeData.pipelineStageId !== afterData.pipelineStageId;
    const statusChanged = normalizeStatus(beforeData.status) !== normalizeStatus(afterData.status);
    if (!stageChanged && !statusChanged) return;

    const applicationId = asTrimmedString(event.params.applicationId);
    const candidateUid = asTrimmedString(afterData.candidate_uid ?? (afterData as unknown as JsonRecord).candidateId);
    if (!applicationId || !candidateUid) return;

    const companyUid =
      asTrimmedString(afterData.company_uid) ||
      asTrimmedString((afterData as unknown as JsonRecord).companyUid);

    const feedback = buildFeedback({
      beforeData,
      afterData,
      stageChanged,
      statusChanged,
    });
    const generatedAtIso = new Date().toISOString();
    const feedbackEntry = {
      trigger: feedback.trigger,
      title: feedback.title,
      message: feedback.message,
      actions: feedback.actions,
      status: normalizeStatus(afterData.status),
      stageName: asTrimmedString(afterData.pipelineStageName),
      generatedAt: generatedAtIso,
    };

    const db = getFirestore();
    const applicationRef = db.collection("applications").doc(applicationId);
    const serverNow = FieldValue.serverTimestamp();

    await Promise.all([
      applicationRef.set(
        {
          candidateFeedback: {
            latest: feedbackEntry,
            history: FieldValue.arrayUnion(feedbackEntry),
            updatedAt: serverNow,
          },
          updated_at: serverNow,
          updatedAt: serverNow,
        },
        { merge: true },
      ),
      db.collection("notifications").add({
        type: "candidate_micro_feedback",
        audience: "candidate",
        channel: "in_app",
        userUid: candidateUid,
        companyUid: companyUid || null,
        applicationId,
        title: feedback.title,
        message: feedback.message,
        actions: feedback.actions,
        read: false,
        createdAt: serverNow,
        updatedAt: serverNow,
      }),
      db.collection("auditLogs").add({
        action: "candidate_micro_feedback_generated",
        actorUid: "system",
        actorRole: "system",
        targetType: "application",
        targetId: applicationId,
        companyId: companyUid || null,
        metadata: {
          candidateUid,
          trigger: feedback.trigger,
          status: normalizeStatus(afterData.status),
          stageName: asTrimmedString(afterData.pipelineStageName),
          generatedAt: generatedAtIso,
        },
        timestamp: serverNow,
      }),
    ]);
  },
);
