/**
 * Callable: getApplicationsForReview
 *
 * Serves application data to recruiters / company with LGPD-compliant
 * blind review.  Candidate PII is progressively revealed based on the
 * pipeline stage:
 *
 *   new / screening  → blind   (no name, email, avatar, cover letter)
 *   interview        → partial (name + email + cover letter)
 *   offer / hired    → full    (+ avatar)
 *   rejected         → respects the identityRevealed flag on the doc
 *
 * Admin SDK bypasses Firestore security rules, so clients can no longer
 * query `applications` directly — they MUST go through this callable.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { PipelineStage } from "../../types/pipeline";

// ── Types ──────────────────────────────────────────────────────────

/** Stage types where candidate identity is hidden. */
const BLIND_STAGE_TYPES = new Set<string>(["new", "screening"]);

/** Stage types where name + email + cover letter are shown. */
const PARTIAL_REVEAL_STAGE_TYPES = new Set<string>(["interview"]);

/** Stage types where everything including avatar is shown. */
const FULL_REVEAL_STAGE_TYPES = new Set<string>(["offer", "hired"]);

type RevealLevel = "blind" | "partial" | "full";

export interface BaseApplication {
  applicationId: string;
  candidateId: string;
  jobOfferId: string;
  anonymizedLabel: string;
  status: string;
  pipelineStageId: string | null;
  pipelineStageName: string | null;
  submittedAt: string | null;
  sourceChannel: string | null;
  // Objective metrics — always visible
  matchScore: number | null;
  knockoutPassed: boolean | null;
  knockoutResponses: Record<string, unknown> | null;
  skillsMatched: string[];
  experienceYears: number | null;
  province: string | null;
  hasCoverLetter: boolean;
  hasCurriculum: boolean;
  // Audit
  identityRevealed: boolean;
  assignedTo: string | null;
}

export interface BlindRevealApplication extends BaseApplication {
  revealLevel: "blind";
  candidateName: null;
  candidateEmail: null;
  coverLetter: null;
  candidateAvatarUrl: null;
}

export interface PartialRevealApplication extends BaseApplication {
  revealLevel: "partial";
  candidateName: string | null;
  candidateEmail: string | null;
  coverLetter: string | null;
  candidateAvatarUrl: null;
}

export interface FullRevealApplication extends BaseApplication {
  revealLevel: "full";
  candidateName: string | null;
  candidateEmail: string | null;
  coverLetter: string | null;
  candidateAvatarUrl: string | null;
}

export type BlindApplication =
  | BlindRevealApplication
  | PartialRevealApplication
  | FullRevealApplication;

// ── Helpers ────────────────────────────────────────────────────────

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function buildAnonymizedLabel(candidateUid: string): string {
  const sanitized = candidateUid.replace(/[^A-Za-z0-9]/g, "");
  if (sanitized.length === 0) return "Candidato anónimo";
  return `Candidato #${sanitized.substring(0, 6).toUpperCase()}`;
}

function resolveStageType(
  pipelineStageId: string | undefined,
  stages: PipelineStage[]
): string {
  if (!pipelineStageId) return "new";
  const match = stages.find((s) => s.id === pipelineStageId);
  return match?.type ?? "new";
}

function determineRevealLevel(
  stageType: string,
  identityRevealed: boolean | undefined
): RevealLevel {
  if (FULL_REVEAL_STAGE_TYPES.has(stageType)) return "full";
  if (PARTIAL_REVEAL_STAGE_TYPES.has(stageType)) return "partial";
  if (BLIND_STAGE_TYPES.has(stageType)) return "blind";

  // "rejected" — respect the flag set when the candidate was advanced
  if (stageType === "rejected") {
    return identityRevealed ? "partial" : "blind";
  }

  return "blind";
}

function extractSkillsMatched(
  aiMatchResult: Record<string, unknown> | undefined
): string[] {
  if (!aiMatchResult) return [];
  const skills = aiMatchResult.skillsMatched ?? aiMatchResult.matchedSkills;
  if (Array.isArray(skills)) {
    return skills.map((s: unknown) => String(s)).filter(Boolean);
  }
  // Try to extract from componentScores
  const cs = aiMatchResult.componentScores as
    | Record<string, unknown>
    | undefined;
  if (cs?.matchedSkills && Array.isArray(cs.matchedSkills)) {
    return cs.matchedSkills.map((s: unknown) => String(s)).filter(Boolean);
  }
  return [];
}

function extractExperienceYears(
  aiMatchResult: Record<string, unknown> | undefined
): number | null {
  if (!aiMatchResult) return null;
  const cs = aiMatchResult.componentScores as
    | Record<string, unknown>
    | undefined;
  const years = cs?.experienceYears ?? aiMatchResult.experienceYears;
  if (typeof years === "number" && Number.isFinite(years)) return years;
  return null;
}

function extractProvince(
  aiMatchResult: Record<string, unknown> | undefined
): string | null {
  if (!aiMatchResult) return null;
  const cs = aiMatchResult.componentScores as
    | Record<string, unknown>
    | undefined;
  const province = cs?.candidateProvince ?? aiMatchResult.candidateProvince;
  if (typeof province === "string" && province.trim().length > 0) {
    return province.trim();
  }
  return null;
}

function timestampToIso(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value === "object" && value !== null) {
    const maybeTs = value as { toDate?: () => Date };
    if (typeof maybeTs.toDate === "function") {
      try {
        return maybeTs.toDate().toISOString();
      } catch {
        return null;
      }
    }
  }
  if (value instanceof Date) return value.toISOString();
  if (typeof value === "string") return value;
  return null;
}

function projectApplication(
  docId: string,
  offerId: string,
  data: Record<string, unknown>,
  stages: PipelineStage[]
): BlindApplication {
  const candidateUid = asTrimmedString(
    data.candidate_uid ?? data.candidateId
  );
  const stageType = resolveStageType(
    asTrimmedString(data.pipelineStageId) || undefined,
    stages
  );
  const level = determineRevealLevel(
    stageType,
    data.identityRevealed as boolean | undefined
  );

  const aiMatch = data.aiMatchResult as
    | Record<string, unknown>
    | undefined;

  // Base — always visible
  const base: BaseApplication = {
    applicationId: docId,
    candidateId: candidateUid,
    jobOfferId: offerId,
    anonymizedLabel: buildAnonymizedLabel(candidateUid),
    status: asTrimmedString(data.status) || "pending",
    pipelineStageId: asTrimmedString(data.pipelineStageId) || null,
    pipelineStageName: asTrimmedString(data.pipelineStageName) || null,
    submittedAt: timestampToIso(data.submitted_at ?? data.submittedAt),
    sourceChannel: asTrimmedString(data.source_channel ?? data.sourceChannel) || null,
    matchScore:
      typeof data.match_score === "number" ? data.match_score : null,
    knockoutPassed:
      typeof data.knockoutPassed === "boolean" ? data.knockoutPassed : null,
    knockoutResponses:
      (data.knockoutResponses as Record<string, unknown>) ?? null,
    skillsMatched: extractSkillsMatched(aiMatch),
    experienceYears: extractExperienceYears(aiMatch),
    province: extractProvince(aiMatch),
    hasCoverLetter: Boolean(data.cover_letter ?? data.coverLetter),
    hasCurriculum: Boolean(data.curriculum_id ?? data.curriculumId),
    identityRevealed: data.identityRevealed === true,
    assignedTo: asTrimmedString(data.assignedTo) || null,
  };

  if (level === "full") {
    return {
      ...base,
      revealLevel: "full",
      candidateName: asTrimmedString(data.candidate_name ?? data.candidateName) || null,
      candidateEmail: asTrimmedString(data.candidate_email ?? data.candidateEmail) || null,
      coverLetter: asTrimmedString(data.cover_letter ?? data.coverLetter) || null,
      candidateAvatarUrl: asTrimmedString(data.candidate_avatar_url ?? data.candidateAvatarUrl) || null,
    } satisfies FullRevealApplication;
  }

  if (level === "partial") {
    return {
      ...base,
      revealLevel: "partial",
      candidateName: asTrimmedString(data.candidate_name ?? data.candidateName) || null,
      candidateEmail: asTrimmedString(data.candidate_email ?? data.candidateEmail) || null,
      coverLetter: asTrimmedString(data.cover_letter ?? data.coverLetter) || null,
      candidateAvatarUrl: null,
    } satisfies PartialRevealApplication;
  }

  // level === "blind"
  return {
    ...base,
    revealLevel: "blind",
    candidateName: null,
    candidateEmail: null,
    coverLetter: null,
    candidateAvatarUrl: null,
  } satisfies BlindRevealApplication;
}

// ── Callable ───────────────────────────────────────────────────────

export const getApplicationsForReview = onCall(
  { region: "europe-west1", memory: "512MiB" },
  async (request): Promise<{ applications: BlindApplication[] }> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const { jobOfferId } = request.data as { jobOfferId?: string };
    const normalizedOfferId = (jobOfferId ?? "").trim();
    if (!normalizedOfferId) {
      throw new HttpsError(
        "invalid-argument",
        "jobOfferId es obligatorio."
      );
    }

    const db = getFirestore();
    const callerUid = request.auth.uid;

    // 1. Read job offer to get company_uid + pipeline stages
    const offerDoc = await db
      .collection("jobOffers")
      .doc(normalizedOfferId)
      .get();
    if (!offerDoc.exists) {
      throw new HttpsError("not-found", "Oferta no encontrada.");
    }

    const offerData = offerDoc.data() as Record<string, unknown>;
    const companyUid = asTrimmedString(
      offerData.company_uid ?? offerData.companyUid ?? offerData.owner_uid
    );

    if (!companyUid) {
      throw new HttpsError(
        "failed-precondition",
        "La oferta no tiene empresa asociada."
      );
    }

    // 2. Verify caller has access to this company
    const isCompanyOwner = callerUid === companyUid;
    let callerRole = "";

    if (!isCompanyOwner) {
      const recruiterDoc = await db
        .collection("recruiters")
        .doc(callerUid)
        .get();
      if (!recruiterDoc.exists) {
        throw new HttpsError(
          "permission-denied",
          "No tienes acceso a esta oferta."
        );
      }
      const recruiterData = recruiterDoc.data() as Record<string, unknown>;
      if (
        asTrimmedString(recruiterData.companyId) !== companyUid ||
        asTrimmedString(recruiterData.status) !== "active"
      ) {
        throw new HttpsError(
          "permission-denied",
          "No tienes acceso a esta oferta."
        );
      }
      callerRole = asTrimmedString(recruiterData.role);
      const allowedRoles = new Set([
        "admin",
        "recruiter",
        "hiring_manager",
        "viewer",
        "external_evaluator",
      ]);
      if (!allowedRoles.has(callerRole)) {
        throw new HttpsError(
          "permission-denied",
          "Tu rol no tiene acceso a candidaturas."
        );
      }
    }

    // 3. Fetch applications for this offer (Admin SDK — bypasses rules)
    const pipelineStages = (offerData.pipelineStages ?? []) as PipelineStage[];

    const applicationsSnapshot = await db
      .collection("applications")
      .where("jobOfferId", "==", normalizedOfferId)
      .get();

    // 4. Project each application based on its stage
    const isExternalEvaluator = callerRole === "external_evaluator";
    const results: BlindApplication[] = [];

    for (const doc of applicationsSnapshot.docs) {
      const data = doc.data() as Record<string, unknown>;

      // External evaluators only see applications assigned to them
      if (isExternalEvaluator) {
        const assignedTo = asTrimmedString(data.assignedTo);
        const assignedEval = asTrimmedString(data.assignedEvaluatorUid);
        const evalUids = Array.isArray(data.externalEvaluatorUids)
          ? data.externalEvaluatorUids.map(String)
          : [];
        if (
          assignedTo !== callerUid &&
          assignedEval !== callerUid &&
          !evalUids.includes(callerUid)
        ) {
          continue;
        }
      }

      results.push(projectApplication(doc.id, normalizedOfferId, data, pipelineStages));
    }

    return { applications: results };
  }
);
