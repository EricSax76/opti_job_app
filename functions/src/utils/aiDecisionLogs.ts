import * as admin from "firebase-admin";

type JsonRecord = Record<string, unknown>;

export interface AiDecisionLogModelInfo {
  provider: string;
  model: string;
  version: string;
  source?: string;
}

export interface AiDecisionWeights {
  semanticWeight: number;
  skillsWeight: number;
  locationWeight: number;
  experienceWeight: number;
}

export interface AiDecisionLogPayload {
  applicationId: string;
  companyId?: string | null;
  candidateUid?: string | null;
  jobOfferId?: string | null;
  decisionType: "vector_match" | "skill_match" | "human_override";
  decisionStatus: "generated" | "overridden";
  score?: number | null;
  previousScore?: number | null;
  weights?: Partial<AiDecisionWeights>;
  model: AiDecisionLogModelInfo;
  requestId: string;
  executionId: string;
  features: JsonRecord;
  metadata?: JsonRecord;
  actorUid?: string | null;
  actorRole?: string | null;
}

function asNullableString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const normalized = String(value).trim();
  return normalized.length > 0 ? normalized : null;
}

function toNullableNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return null;
  return parsed;
}

function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

export async function writeAiDecisionLog(
  payload: AiDecisionLogPayload,
): Promise<string> {
  const db = admin.firestore();
  const ref = db.collection("aiDecisionLogs").doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  await ref.set({
    applicationId: payload.applicationId,
    companyId: asNullableString(payload.companyId),
    candidateUid: asNullableString(payload.candidateUid),
    jobOfferId: asNullableString(payload.jobOfferId),
    decisionType: payload.decisionType,
    decisionStatus: payload.decisionStatus,
    score: toNullableNumber(payload.score),
    previousScore: toNullableNumber(payload.previousScore),
    weights: {
      semanticWeight: toNullableNumber(payload.weights?.semanticWeight),
      skillsWeight: toNullableNumber(payload.weights?.skillsWeight),
      locationWeight: toNullableNumber(payload.weights?.locationWeight),
      experienceWeight: toNullableNumber(payload.weights?.experienceWeight),
    },
    model: {
      provider: payload.model.provider,
      model: payload.model.model,
      version: payload.model.version,
      source: asNullableString(payload.model.source),
    },
    executionId: payload.executionId,
    requestId: payload.requestId,
    features: asRecord(payload.features),
    metadata: asRecord(payload.metadata),
    actorUid: asNullableString(payload.actorUid),
    actorRole: asNullableString(payload.actorRole),
    createdAt: now,
    updatedAt: now,
  });

  return ref.id;
}

export async function writeAuditLog({
  action,
  actorUid,
  actorRole,
  targetType,
  targetId,
  companyId,
  metadata,
}: {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  companyId?: string | null;
  metadata?: JsonRecord;
}): Promise<void> {
  await admin.firestore().collection("auditLogs").add({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: asNullableString(companyId),
    metadata: asRecord(metadata),
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

