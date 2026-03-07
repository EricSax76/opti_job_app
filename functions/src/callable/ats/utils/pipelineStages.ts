import { PipelineStage } from "../../../types/pipeline";

type JsonRecord = Record<string, unknown>;

const VALID_STAGE_TYPES = new Set<PipelineStage["type"]>([
  "new",
  "screening",
  "interview",
  "offer",
  "hired",
  "rejected",
]);

function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

function asTrimmedString(value: unknown): string {
  if (value == null) return "";
  return String(value).trim();
}

function asFiniteInt(value: unknown, fallback: number): number {
  const parsed =
    typeof value === "number" ? value : Number.parseInt(String(value), 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.trunc(parsed);
}

function normalizeStageType(value: unknown): PipelineStage["type"] {
  const normalized = asTrimmedString(value).toLowerCase();
  if (VALID_STAGE_TYPES.has(normalized as PipelineStage["type"])) {
    return normalized as PipelineStage["type"];
  }
  return "new";
}

function normalizePipelineStages(raw: unknown): PipelineStage[] {
  if (!Array.isArray(raw)) return [];

  const stages: PipelineStage[] = [];
  for (let index = 0; index < raw.length; index += 1) {
    const record = asRecord(raw[index]);
    const id = asTrimmedString(record.id);
    if (!id) continue;

    stages.push({
      id,
      name: asTrimmedString(record.name) || `Stage ${index + 1}`,
      order: asFiniteInt(record.order, index),
      type: normalizeStageType(record.type),
    });
  }

  return stages;
}

function resolvePipelineId(offerData: JsonRecord): string {
  return asTrimmedString(offerData.pipelineId ?? offerData.pipeline_id);
}

async function readPipelineStagesFromCollection({
  db,
  transaction,
  pipelineId,
}: {
  db: FirebaseFirestore.Firestore;
  transaction?: FirebaseFirestore.Transaction;
  pipelineId: string;
}): Promise<PipelineStage[]> {
  if (!pipelineId) return [];
  const pipelineRef = db.collection("pipelines").doc(pipelineId);
  const pipelineSnap = transaction
    ? await transaction.get(pipelineRef)
    : await pipelineRef.get();

  if (!pipelineSnap.exists) return [];
  const pipelineData = asRecord(pipelineSnap.data());
  return normalizePipelineStages(pipelineData.stages);
}

export async function resolveOfferPipelineStages({
  db,
  offerData,
  transaction,
}: {
  db: FirebaseFirestore.Firestore;
  offerData: JsonRecord;
  transaction?: FirebaseFirestore.Transaction;
}): Promise<PipelineStage[]> {
  const pipelineId = resolvePipelineId(offerData);
  const pipelineStages = await readPipelineStagesFromCollection({
    db,
    transaction,
    pipelineId,
  });
  if (pipelineStages.length > 0) return pipelineStages;

  return normalizePipelineStages(
    offerData.pipelineStages ?? offerData.pipeline_stages,
  );
}
