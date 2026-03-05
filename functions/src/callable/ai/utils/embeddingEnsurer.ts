import * as admin from "firebase-admin";
import {
  buildCandidateEmbeddingText,
  buildJobOfferEmbeddingText,
  generateEmbedding,
  hashText,
} from "../../../utils/embeddings";
import { asRecord, asTrimmedString, JsonRecord, parseVector } from "./matchingLogic";

export async function resolveCurriculumDoc({
  db,
  candidateUid,
  curriculumId,
}: {
  db: FirebaseFirestore.Firestore;
  candidateUid: string;
  curriculumId: string;
}): Promise<{ curriculumId: string; data: JsonRecord }> {
  const requestedId = asTrimmedString(curriculumId);
  const candidateCurriculumsRef = db
    .collection("candidates")
    .doc(candidateUid)
    .collection("curriculum");

  if (requestedId) {
    const requestedDoc = await candidateCurriculumsRef.doc(requestedId).get();
    if (requestedDoc.exists) {
      return {
        curriculumId: requestedId,
        data: asRecord(requestedDoc.data()),
      };
    }
  }

  const mainDoc = await candidateCurriculumsRef.doc("main").get();
  if (mainDoc.exists) {
    return {
      curriculumId: "main",
      data: asRecord(mainDoc.data()),
    };
  }

  const fallbackDoc = requestedId
    ? await db.collection("curriculum").doc(requestedId).get()
    : null;
  if (fallbackDoc?.exists) {
    return {
      curriculumId: requestedId,
      data: asRecord(fallbackDoc.data()),
    };
  }

  return {
    curriculumId: requestedId || "main",
    data: {},
  };
}

export async function ensureCandidateEmbedding({
  db,
  candidateUid,
  curriculumId,
  candidateData,
  curriculumData,
}: {
  db: FirebaseFirestore.Firestore;
  candidateUid: string;
  curriculumId: string;
  candidateData: JsonRecord;
  curriculumData: JsonRecord;
}): Promise<{
  vector: number[];
  model: JsonRecord;
  source: string;
  textHash: string;
}> {
  const ref = db.collection("candidateEmbeddings").doc(candidateUid);
  const snapshot = await ref.get();
  const existing = asRecord(snapshot.data());

  const text = buildCandidateEmbeddingText({
    candidate: candidateData,
    curriculum: curriculumData,
  });
  const textHash = hashText(text);
  const existingHash = asTrimmedString(existing.profileTextHash);
  const existingVector = parseVector(existing.profileEmbedding);

  if (existingHash === textHash && existingVector.length > 0) {
    return {
      vector: existingVector,
      model: asRecord(existing.embeddingModel),
      source: asTrimmedString(existing.embeddingSource) || "cache",
      textHash,
    };
  }

  const embedding = await generateEmbedding({
    text,
    taskType: "RETRIEVAL_DOCUMENT",
  });

  const now = admin.firestore.FieldValue.serverTimestamp();
  await ref.set({
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
    updatedAt: now,
    createdAt: snapshot.exists ? existing.createdAt ?? now : now,
  }, { merge: true });

  return {
    vector: embedding.vector,
    model: {
      provider: embedding.metadata.provider,
      model: embedding.metadata.model,
      version: embedding.metadata.version,
      dimension: embedding.metadata.dimension,
    },
    source: embedding.metadata.source,
    textHash,
  };
}

export async function ensureOfferEmbedding({
  offerRef,
  offerData,
}: {
  offerRef: FirebaseFirestore.DocumentReference;
  offerData: JsonRecord;
}): Promise<{
  vector: number[];
  model: JsonRecord;
  source: string;
  textHash: string;
}> {
  const text = buildJobOfferEmbeddingText(offerData);
  const textHash = hashText(text);
  const existingHash = asTrimmedString(offerData.requirementsEmbeddingHash);
  const existingVector = parseVector(offerData.requirementsEmbedding);

  if (existingHash === textHash && existingVector.length > 0) {
    return {
      vector: existingVector,
      model: asRecord(offerData.embeddingModel),
      source: asTrimmedString(offerData.embeddingSource) || "cache",
      textHash,
    };
  }

  const embedding = await generateEmbedding({
    text,
    taskType: "RETRIEVAL_DOCUMENT",
  });
  const now = admin.firestore.FieldValue.serverTimestamp();

  await offerRef.set({
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
    embeddingUpdatedAt: now,
  }, { merge: true });

  return {
    vector: embedding.vector,
    model: {
      provider: embedding.metadata.provider,
      model: embedding.metadata.model,
      version: embedding.metadata.version,
      dimension: embedding.metadata.dimension,
    },
    source: embedding.metadata.source,
    textHash,
  };
}
