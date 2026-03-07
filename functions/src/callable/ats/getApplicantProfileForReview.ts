import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { PipelineStage } from "../../types/pipeline";
import { resolveOfferPipelineStages } from "./utils/pipelineStages";

type RevealLevel = "blind" | "partial" | "full";

const BLIND_STAGE_TYPES = new Set<string>(["new", "screening"]);
const PARTIAL_REVEAL_STAGE_TYPES = new Set<string>(["interview"]);
const FULL_REVEAL_STAGE_TYPES = new Set<string>(["offer", "hired"]);
const PARTIAL_REVEAL_STATUSES = new Set<string>(["interview", "interviewing"]);
const FULL_REVEAL_STATUSES = new Set<string>([
  "offered",
  "accepted_pending_signature",
  "accepted",
  "hired",
]);
const RECRUITER_ALLOWED_ROLES = new Set([
  "admin",
  "recruiter",
  "hiring_manager",
  "viewer",
  "external_evaluator",
]);

function asRecord(value: unknown): Record<string, unknown> {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as Record<string, unknown>;
}

function asTrimmedString(value: unknown): string {
  if (value == null) return "";
  return String(value).trim();
}

function timestampToMillis(value: unknown): number {
  if (value == null) return 0;
  if (typeof value === "object" && value !== null) {
    const maybeTimestamp = value as { toDate?: () => Date };
    if (typeof maybeTimestamp.toDate === "function") {
      try {
        return maybeTimestamp.toDate().getTime();
      } catch {
        return 0;
      }
    }
  }
  if (value instanceof Date) return value.getTime();
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

function applicationRecency(data: Record<string, unknown>): number {
  return Math.max(
    timestampToMillis(data.updated_at),
    timestampToMillis(data.updatedAt),
    timestampToMillis(data.submitted_at),
    timestampToMillis(data.submittedAt),
    timestampToMillis(data.created_at),
    timestampToMillis(data.createdAt),
  );
}

async function resolveApplicationIdFallback({
  db,
  offerId,
  candidateUid,
}: {
  db: FirebaseFirestore.Firestore;
  offerId: string;
  candidateUid: string;
}): Promise<string> {
  const [offerIdSnapshot, legacyOfferIdSnapshot] = await Promise.all([
    db.collection("applications").where("jobOfferId", "==", offerId).limit(200).get(),
    db.collection("applications").where("job_offer_id", "==", offerId).limit(200).get(),
  ]);

  const byId = new Map<string, Record<string, unknown>>();
  for (const snapshot of [offerIdSnapshot, legacyOfferIdSnapshot]) {
    for (const doc of snapshot.docs) {
      const data = asRecord(doc.data());
      const appCandidateUid = asTrimmedString(
        data.candidate_uid ?? data.candidateId,
      );
      if (appCandidateUid !== candidateUid) continue;
      byId.set(doc.id, data);
    }
  }

  let bestId = "";
  let bestRecency = -1;
  for (const [id, data] of byId.entries()) {
    const recency = applicationRecency(data);
    if (recency > bestRecency) {
      bestRecency = recency;
      bestId = id;
    }
  }

  return bestId;
}

function resolveStageType(
  pipelineStageId: string | undefined,
  stages: PipelineStage[],
): string {
  if (!pipelineStageId) return "new";
  const match = stages.find((stage) => stage.id === pipelineStageId);
  return match?.type ?? "new";
}

function determineRevealLevel(
  stageType: string,
  identityRevealed: boolean | undefined,
): RevealLevel {
  if (FULL_REVEAL_STAGE_TYPES.has(stageType)) return "full";
  if (PARTIAL_REVEAL_STAGE_TYPES.has(stageType)) return "partial";
  if (BLIND_STAGE_TYPES.has(stageType)) return "blind";
  if (stageType === "rejected") {
    return identityRevealed ? "partial" : "blind";
  }
  return "blind";
}

function withLegacyStatusFallback({
  level,
  status,
  identityRevealed,
}: {
  level: RevealLevel;
  status: string;
  identityRevealed: boolean | undefined;
}): RevealLevel {
  if (level !== "blind") return level;
  if (FULL_REVEAL_STATUSES.has(status)) return "full";
  if (PARTIAL_REVEAL_STATUSES.has(status)) return "partial";
  if (identityRevealed === true) return "partial";
  return level;
}

function isExternalEvaluatorAssigned(
  callerUid: string,
  applicationData: Record<string, unknown>,
): boolean {
  const assignedTo = asTrimmedString(applicationData.assignedTo);
  const assignedEvaluatorUid = asTrimmedString(
    applicationData.assignedEvaluatorUid,
  );
  const externalEvaluatorUids = Array.isArray(
    applicationData.externalEvaluatorUids,
  )
    ? applicationData.externalEvaluatorUids.map(String)
    : [];
  return (
    assignedTo === callerUid ||
    assignedEvaluatorUid === callerUid ||
    externalEvaluatorUids.includes(callerUid)
  );
}

export const getApplicantProfileForReview = onCall(
  { region: "europe-west1", memory: "256MiB" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const requestedApplicationId = asTrimmedString(request.data?.applicationId);
    const fallbackOfferId = asTrimmedString(
      request.data?.jobOfferId ?? request.data?.offerId,
    );
    const fallbackCandidateUid = asTrimmedString(request.data?.candidateUid);

    const db = getFirestore();
    let applicationId = requestedApplicationId;
    if (!applicationId) {
      if (!fallbackOfferId || !fallbackCandidateUid) {
        throw new HttpsError(
          "invalid-argument",
          "applicationId es obligatorio; usa fallback con jobOfferId + candidateUid.",
        );
      }
      applicationId = await resolveApplicationIdFallback({
        db,
        offerId: fallbackOfferId,
        candidateUid: fallbackCandidateUid,
      });
      if (!applicationId) {
        throw new HttpsError(
          "not-found",
          "No se encontró candidatura para candidateUid en la oferta indicada.",
        );
      }
    }

    const callerUid = request.auth.uid;
    const applicationSnap = await db
      .collection("applications")
      .doc(applicationId)
      .get();
    if (!applicationSnap.exists) {
      throw new HttpsError("not-found", "Postulación no encontrada.");
    }

    const applicationData = asRecord(applicationSnap.data());
    const offerId = asTrimmedString(
      applicationData.jobOfferId ?? applicationData.job_offer_id,
    );
    if (!offerId) {
      throw new HttpsError(
        "failed-precondition",
        "La postulación no tiene oferta asociada.",
      );
    }

    const offerSnap = await db.collection("jobOffers").doc(offerId).get();
    if (!offerSnap.exists) {
      throw new HttpsError("not-found", "Oferta no encontrada.");
    }

    const offerData = asRecord(offerSnap.data());
    const companyUid = asTrimmedString(
      offerData.company_uid ?? offerData.companyUid ?? offerData.owner_uid,
    );
    if (!companyUid) {
      throw new HttpsError(
        "failed-precondition",
        "La oferta no tiene empresa asociada.",
      );
    }

    const isCompanyOwner = callerUid === companyUid;
    let callerRole = "";

    if (!isCompanyOwner) {
      const recruiterSnap = await db.collection("recruiters").doc(callerUid).get();
      if (!recruiterSnap.exists) {
        throw new HttpsError(
          "permission-denied",
          "No tienes acceso a esta candidatura.",
        );
      }

      const recruiterData = asRecord(recruiterSnap.data());
      if (
        asTrimmedString(recruiterData.companyId) !== companyUid ||
        asTrimmedString(recruiterData.status) !== "active"
      ) {
        throw new HttpsError(
          "permission-denied",
          "No tienes acceso a esta candidatura.",
        );
      }

      callerRole = asTrimmedString(recruiterData.role);
      if (!RECRUITER_ALLOWED_ROLES.has(callerRole)) {
        throw new HttpsError(
          "permission-denied",
          "Tu rol no tiene acceso a esta candidatura.",
        );
      }

      if (
        callerRole === "external_evaluator" &&
        !isExternalEvaluatorAssigned(callerUid, applicationData)
      ) {
        throw new HttpsError(
          "permission-denied",
          "No tienes acceso a esta candidatura.",
        );
      }
    }

    const stages = await resolveOfferPipelineStages({
      db,
      offerData,
    });
    const stageType = resolveStageType(
      asTrimmedString(applicationData.pipelineStageId) || undefined,
      stages,
    );
    const baseRevealLevel = determineRevealLevel(
      stageType,
      applicationData.identityRevealed === true,
    );
    const revealLevel = withLegacyStatusFallback({
      level: baseRevealLevel,
      status: asTrimmedString(applicationData.status).toLowerCase(),
      identityRevealed: applicationData.identityRevealed === true,
    });
    if (revealLevel === "blind") {
      throw new HttpsError(
        "permission-denied",
        "El perfil permanece anonimizado en esta etapa.",
      );
    }

    const candidateUid = asTrimmedString(
      applicationData.candidate_uid ?? applicationData.candidateId,
    );
    if (!candidateUid) {
      throw new HttpsError(
        "failed-precondition",
        "La candidatura no tiene candidato asociado.",
      );
    }

    const curriculumId =
      asTrimmedString(
        applicationData.curriculum_id ?? applicationData.curriculumId,
      ) || "main";
    const candidateRef = db.collection("candidates").doc(candidateUid);
    const curriculumRef = candidateRef.collection("curriculum").doc(curriculumId);
    const coverLetterRef = candidateRef.collection("cover_letter").doc("main");

    const [candidateSnap, curriculumSnap, coverLetterSnap] = await Promise.all([
      candidateRef.get(),
      curriculumRef.get(),
      coverLetterRef.get(),
    ]);

    if (!candidateSnap.exists) {
      throw new HttpsError("not-found", "Perfil de candidato no encontrado.");
    }

    const candidateData: Record<string, unknown> = {
      ...asRecord(candidateSnap.data()),
      uid: asTrimmedString(candidateSnap.data()?.uid) || candidateUid,
    };

    if (revealLevel !== "full") {
      delete candidateData.avatar_url;
      delete candidateData.avatarUrl;
    }

    delete candidateData.token;

    const coverLetterData = asRecord(coverLetterSnap.data());
    if (Object.keys(coverLetterData).length > 0) {
      candidateData.cover_letter = coverLetterData;
    }

    const videoCurriculum = asRecord(candidateData.video_curriculum);
    const hasVideoCurriculum =
      asTrimmedString(videoCurriculum.storage_path).length > 0;
    const canViewVideoCurriculum = revealLevel === "full";
    if (!hasVideoCurriculum || !canViewVideoCurriculum) {
      delete candidateData.video_curriculum;
    }

    const curriculumData = asRecord(curriculumSnap.data());

    return {
      revealLevel,
      candidate: candidateData,
      curriculum: curriculumData,
      hasVideoCurriculum,
      canViewVideoCurriculum,
      applicationId,
    };
  },
);
