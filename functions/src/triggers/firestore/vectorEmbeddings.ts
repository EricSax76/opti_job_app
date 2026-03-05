import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import {
  buildCandidateEmbeddingText,
  buildJobOfferEmbeddingText,
  generateEmbedding,
  hashText,
} from "../../utils/embeddings";

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

function parseVector(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  const vector: number[] = [];
  for (const item of value) {
    const parsed = Number(item);
    if (!Number.isFinite(parsed)) continue;
    vector.push(parsed);
  }
  return vector;
}

export const onCurriculumWriteRefreshEmbedding = onDocumentWritten(
  {
    document: "candidates/{candidateUid}/curriculum/{curriculumId}",
    region: "europe-west1",
  },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const candidateUid = asTrimmedString(event.params.candidateUid);
    const curriculumId = asTrimmedString(event.params.curriculumId);
    if (!candidateUid || !curriculumId) return;

    const db = getFirestore();
    const [candidateDoc, embeddingDoc] = await Promise.all([
      db.collection("candidates").doc(candidateUid).get(),
      db.collection("candidateEmbeddings").doc(candidateUid).get(),
    ]);

    const candidateData = asRecord(candidateDoc.data());
    const curriculumData = asRecord(after.data());
    const text = buildCandidateEmbeddingText({
      candidate: candidateData,
      curriculum: curriculumData,
    });
    const textHash = hashText(text);

    const existingEmbedding = asRecord(embeddingDoc.data());
    const existingHash = asTrimmedString(existingEmbedding.profileTextHash);
    const existingVector = parseVector(existingEmbedding.profileEmbedding);
    if (existingHash === textHash && existingVector.length > 0) return;

    const embedding = await generateEmbedding({
      text,
      taskType: "RETRIEVAL_DOCUMENT",
    });

    await db.collection("candidateEmbeddings").doc(candidateUid).set({
      candidateUid,
      curriculumId,
      profileTextHash: textHash,
      profileEmbedding: embedding.vector,
      embeddingModel: {
        provider: embedding.metadata.provider,
        model: embedding.metadata.model,
        version: embedding.metadata.version,
        dimension: embedding.metadata.dimension,
      },
      embeddingSource: embedding.metadata.source,
      embeddingLastError: embedding.metadata.lastError ?? null,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: embeddingDoc.exists
        ? (existingEmbedding.createdAt ?? FieldValue.serverTimestamp())
        : FieldValue.serverTimestamp(),
    }, { merge: true });
  },
);

export const onJobOfferWriteRefreshEmbedding = onDocumentWritten(
  {
    document: "jobOffers/{offerId}",
    region: "europe-west1",
  },
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const offerId = asTrimmedString(event.params.offerId);
    if (!offerId) return;

    const offerData = asRecord(after.data());
    const text = buildJobOfferEmbeddingText(offerData);
    const textHash = hashText(text);
    const existingHash = asTrimmedString(offerData.requirementsEmbeddingHash);
    const existingVector = parseVector(offerData.requirementsEmbedding);
    if (existingHash === textHash && existingVector.length > 0) return;

    const embedding = await generateEmbedding({
      text,
      taskType: "RETRIEVAL_DOCUMENT",
    });

    await after.ref.set({
      requirementsEmbedding: embedding.vector,
      requirementsEmbeddingHash: textHash,
      embeddingModel: {
        provider: embedding.metadata.provider,
        model: embedding.metadata.model,
        version: embedding.metadata.version,
        dimension: embedding.metadata.dimension,
      },
      embeddingSource: embedding.metadata.source,
      embeddingLastError: embedding.metadata.lastError ?? null,
      embeddingUpdatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  },
);

