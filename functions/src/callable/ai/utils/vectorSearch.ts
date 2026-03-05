import { GoogleAuth } from "google-auth-library";
import { cosineScore01 } from "../../../utils/embeddings";
import { asRecord, asTrimmedString, parseVector } from "./matchingLogic";

const GOOGLE_CLOUD_SCOPE = "https://www.googleapis.com/auth/cloud-platform";

export interface NeighborResult {
  offerId: string;
  similarity: number;
  title: string;
}

export function decodeFirestoreValue(value: unknown): unknown {
  const data = asRecord(value);
  if (Object.prototype.hasOwnProperty.call(data, "nullValue")) return null;
  if (Object.prototype.hasOwnProperty.call(data, "stringValue")) return asTrimmedString(data.stringValue);
  if (Object.prototype.hasOwnProperty.call(data, "booleanValue")) return Boolean(data.booleanValue);
  if (Object.prototype.hasOwnProperty.call(data, "integerValue")) {
    const parsed = Number(data.integerValue);
    return Number.isFinite(parsed) ? parsed : null;
  }
  if (Object.prototype.hasOwnProperty.call(data, "doubleValue")) {
    const parsed = Number(data.doubleValue);
    return Number.isFinite(parsed) ? parsed : null;
  }
  if (Object.prototype.hasOwnProperty.call(data, "timestampValue")) return asTrimmedString(data.timestampValue);
  if (Object.prototype.hasOwnProperty.call(data, "arrayValue")) {
    const arrayValue = asRecord(data.arrayValue);
    const values = Array.isArray(arrayValue.values) ? arrayValue.values : [];
    return values.map((item) => decodeFirestoreValue(item));
  }
  if (Object.prototype.hasOwnProperty.call(data, "mapValue")) {
    const mapValue = asRecord(data.mapValue);
    const fields = asRecord(mapValue.fields);
    const output: Record<string, unknown> = {};
    for (const [key, typedValue] of Object.entries(fields)) {
      output[key] = decodeFirestoreValue(typedValue);
    }
    return output;
  }
  return null;
}

export async function tryFirestoreVectorSearchRest({
  queryVector,
  limit,
}: {
  queryVector: number[];
  limit: number;
}): Promise<NeighborResult[] | null> {
  if (queryVector.length === 0) return null;

  try {
    const auth = new GoogleAuth({
      scopes: [GOOGLE_CLOUD_SCOPE],
    });
    const projectId = await auth.getProjectId();
    if (!projectId) return null;

    const client = await auth.getClient();
    const token = await client.getAccessToken();
    const accessToken = asTrimmedString(token.token ?? token);
    if (!accessToken) return null;

    const endpoint = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:runQuery`;
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: "jobOffers" }],
          select: {
            fields: [
              { fieldPath: "title" },
              { fieldPath: "requirementsEmbedding" },
            ],
          },
          findNearest: {
            vectorField: { fieldPath: "requirementsEmbedding" },
            queryVector: {
              arrayValue: {
                values: queryVector.map((value) => ({ doubleValue: value })),
              },
            },
            distanceMeasure: "COSINE",
            distanceResultField: "vectorDistance",
            limit,
          },
        },
      }),
    });

    if (!response.ok) return null;
    const payload = await response.json();
    if (!Array.isArray(payload)) return null;

    const neighbors: NeighborResult[] = [];
    for (const row of payload) {
      const item = asRecord(row);
      const documentData = asRecord(item.document);
      const fullName = asTrimmedString(documentData.name);
      const fields = asRecord(documentData.fields);
      const requirementsEmbedding = decodeFirestoreValue(fields.requirementsEmbedding);
      const parsedVector = parseVector(requirementsEmbedding);
      if (parsedVector.length === 0) continue;

      const pathParts = fullName.split("/");
      const offerId = pathParts.length > 0 ? pathParts[pathParts.length - 1] : "";
      if (!offerId) continue;

      const titleValue = decodeFirestoreValue(fields.title);
      const title = typeof titleValue === "string" ? titleValue : "";

      neighbors.push({
        offerId,
        similarity: cosineScore01(queryVector, parsedVector),
        title,
      });
    }
    return neighbors;
  } catch (_error) {
    return null;
  }
}

export async function tryFirestoreVectorSearch({
  db,
  queryVector,
  limit,
}: {
  db: FirebaseFirestore.Firestore;
  queryVector: number[];
  limit: number;
}): Promise<NeighborResult[] | null> {
  const restResult = await tryFirestoreVectorSearchRest({
    queryVector,
    limit,
  });
  if (restResult && restResult.length > 0) {
    return restResult;
  }

  const baseQuery = db.collection("jobOffers");
  const queryLike = baseQuery as unknown as {
    findNearest?: (...args: unknown[]) => unknown;
  };

  if (typeof queryLike.findNearest !== "function") {
    return null;
  }

  const runCandidate = async (candidateQuery: unknown): Promise<NeighborResult[] | null> => {
    const queryRecord = candidateQuery as { get?: () => Promise<FirebaseFirestore.QuerySnapshot> };
    if (typeof queryRecord.get !== "function") return null;
    const snapshot = await queryRecord.get();
    const neighbors: NeighborResult[] = [];
    for (const doc of snapshot.docs) {
      const data = asRecord(doc.data());
      const offerVector = parseVector(data.requirementsEmbedding);
      if (offerVector.length === 0) continue;
      neighbors.push({
        offerId: doc.id,
        similarity: cosineScore01(queryVector, offerVector),
        title: asTrimmedString(data.title),
      });
    }
    return neighbors;
  };

  try {
    const firstSignature = queryLike.findNearest(
      "requirementsEmbedding",
      queryVector,
      {
        limit,
        distanceMeasure: "COSINE",
      },
    );
    const result = await runCandidate(firstSignature);
    if (result) return result;
  } catch (_error) {
    // Try alternate signature used by some SDK versions.
  }

  try {
    const secondSignature = queryLike.findNearest({
      vectorField: "requirementsEmbedding",
      queryVector,
      limit,
      distanceMeasure: "COSINE",
    });
    const result = await runCandidate(secondSignature);
    if (result) return result;
  } catch (_error) {
    return null;
  }

  return null;
}

export async function manualNeighborSearch({
  db,
  queryVector,
  limit,
}: {
  db: FirebaseFirestore.Firestore;
  queryVector: number[];
  limit: number;
}): Promise<NeighborResult[]> {
  const snapshot = await db.collection("jobOffers").limit(300).get();
  const neighbors: NeighborResult[] = [];
  for (const doc of snapshot.docs) {
    const data = asRecord(doc.data());
    const vector = parseVector(data.requirementsEmbedding);
    if (vector.length === 0) continue;
    neighbors.push({
      offerId: doc.id,
      similarity: cosineScore01(queryVector, vector),
      title: asTrimmedString(data.title),
    });
  }

  neighbors.sort((a, b) => b.similarity - a.similarity);
  return neighbors.slice(0, limit);
}
