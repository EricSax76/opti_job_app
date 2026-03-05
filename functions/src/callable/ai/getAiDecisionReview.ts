import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { writeAuditLog } from "../../utils/aiDecisionLogs";

type JsonRecord = Record<string, unknown>;

const ALLOWED_REVIEW_ROLES = new Set([
  "admin",
  "recruiter",
  "hiring_manager",
  "external_evaluator",
  "viewer",
  "legal",
  "auditor",
]);

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

function toIso(value: unknown): string | null {
  if (value == null) return null;
  if (typeof value === "string") return value;
  const maybeTimestamp = value as { toDate?: () => Date };
  if (typeof maybeTimestamp.toDate === "function") {
    return maybeTimestamp.toDate().toISOString();
  }
  return null;
}

async function assertAccess({
  db,
  actorUid,
  candidateUid,
  companyId,
}: {
  db: FirebaseFirestore.Firestore;
  actorUid: string;
  candidateUid: string;
  companyId: string;
}): Promise<"candidate" | "company" | "recruiter"> {
  if (actorUid === candidateUid) return "candidate";
  if (actorUid === companyId) return "company";

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError("permission-denied", "No tienes acceso a esta decisión IA.");
  }
  const recruiter = asRecord(recruiterDoc.data());
  const recruiterCompany = asTrimmedString(recruiter.companyId);
  const recruiterStatus = asTrimmedString(recruiter.status).toLowerCase();
  const recruiterRole = asTrimmedString(recruiter.role);

  if (
    recruiterCompany !== companyId ||
    recruiterStatus !== "active" ||
    !ALLOWED_REVIEW_ROLES.has(recruiterRole)
  ) {
    throw new HttpsError("permission-denied", "Tu rol no puede revisar esta decisión IA.");
  }
  return "recruiter";
}

function mapDecisionLog(doc: FirebaseFirestore.QueryDocumentSnapshot): JsonRecord {
  const data = asRecord(doc.data());
  return {
    id: doc.id,
    applicationId: asTrimmedString(data.applicationId),
    companyId: asTrimmedString(data.companyId),
    candidateUid: asTrimmedString(data.candidateUid),
    jobOfferId: asTrimmedString(data.jobOfferId),
    decisionType: asTrimmedString(data.decisionType),
    decisionStatus: asTrimmedString(data.decisionStatus),
    score: data.score ?? null,
    previousScore: data.previousScore ?? null,
    weights: asRecord(data.weights),
    model: asRecord(data.model),
    requestId: asTrimmedString(data.requestId),
    executionId: asTrimmedString(data.executionId),
    features: asRecord(data.features),
    metadata: asRecord(data.metadata),
    actorUid: asTrimmedString(data.actorUid),
    actorRole: asTrimmedString(data.actorRole),
    createdAt: toIso(data.createdAt),
    updatedAt: toIso(data.updatedAt),
  };
}

export const getAiDecisionReview = onCall({ region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const applicationId = asTrimmedString(request.data?.applicationId);
  const limitRaw = Number(request.data?.limit ?? 20);
  const limit = Math.max(1, Math.min(50, Number.isFinite(limitRaw) ? Math.floor(limitRaw) : 20));

  if (!applicationId) {
    throw new HttpsError("invalid-argument", "applicationId es obligatorio.");
  }

  const db = admin.firestore();
  const appDoc = await db.collection("applications").doc(applicationId).get();
  if (!appDoc.exists) {
    throw new HttpsError("not-found", "La candidatura indicada no existe.");
  }

  const appData = asRecord(appDoc.data());
  const candidateUid =
    asTrimmedString(appData.candidate_uid) ||
    asTrimmedString(appData.candidateId);
  const companyId =
    asTrimmedString(appData.company_uid) ||
    asTrimmedString(appData.companyUid);
  if (!candidateUid || !companyId) {
    throw new HttpsError(
      "failed-precondition",
      "La candidatura no contiene candidate/company válidos.",
    );
  }

  const actorScope = await assertAccess({
    db,
    actorUid: request.auth.uid,
    candidateUid,
    companyId,
  });

  const logsSnapshot = await db
    .collection("aiDecisionLogs")
    .where("applicationId", "==", applicationId)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  const logs = logsSnapshot.docs.map(mapDecisionLog);
  const latest = logs.length > 0 ? logs[0] : null;
  const humanOverride = asRecord(appData.humanOverride);
  const aiMatchResult = asRecord(appData.aiMatchResult);

  await writeAuditLog({
    action: "ai_decision_review_accessed",
    actorUid: request.auth.uid,
    actorRole: actorScope,
    targetType: "application",
    targetId: applicationId,
    companyId,
    metadata: {
      applicationId,
      logCount: logs.length,
      latestDecisionType: latest ? asTrimmedString(latest.decisionType) : null,
    },
  });

  return {
    applicationId,
    candidateUid,
    companyId,
    actorScope,
    aiMatchResult: {
      score: aiMatchResult.score ?? appData.match_score ?? null,
      explanation: aiMatchResult.explanation ?? null,
      modelVersion: aiMatchResult.modelVersion ?? null,
      generatedAt: toIso(aiMatchResult.generatedAt),
      decisionLogId: aiMatchResult.decisionLogId ?? null,
    },
    humanOverride: {
      overriddenBy: humanOverride.overriddenBy ?? null,
      overriddenAt: toIso(humanOverride.overriddenAt),
      originalAiScore: humanOverride.originalAiScore ?? null,
      overrideScore: humanOverride.overrideScore ?? null,
      reason: humanOverride.reason ?? null,
    },
    logs,
  };
});

