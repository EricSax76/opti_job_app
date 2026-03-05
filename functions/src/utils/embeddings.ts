import { createHash } from "crypto";
import { GoogleAuth } from "google-auth-library";
import { asRecord, asTrimmedString } from "./typeGuards";
import {
  asFiniteDimension,
  compactWhitespace,
  hashToIndex,
  l2Normalize,
  toFiniteVector,
} from "./math/vectorUtils";

export * from "./math/vectorUtils";
export * from "./domain/embeddingBuilders";

const DEFAULT_VERTEX_LOCATION = "europe-west4";
const DEFAULT_VERTEX_MODEL = "text-embedding-005";
const GOOGLE_CLOUD_SCOPE = "https://www.googleapis.com/auth/cloud-platform";

const TASK_TYPE_SET = new Set([
  "RETRIEVAL_DOCUMENT",
  "RETRIEVAL_QUERY",
  "SEMANTIC_SIMILARITY",
]);

export interface EmbeddingMetadata {
  provider: "vertex_ai" | "fallback_hashing";
  model: string;
  version: string;
  dimension: number;
  source: "vertex_ai" | "fallback_hashing";
  lastError?: string;
}

export interface EmbeddingResult {
  vector: number[];
  metadata: EmbeddingMetadata;
}

export interface GenerateEmbeddingInput {
  text: string;
  taskType?: string;
  outputDimensionality?: number;
}

function normalizeForHashing(value: string): string {
  return compactWhitespace(
    value
      .toLowerCase()
      .replace(/[áàâä]/g, "a")
      .replace(/[éèêë]/g, "e")
      .replace(/[íìîï]/g, "i")
      .replace(/[óòôö]/g, "o")
      .replace(/[úùûü]/g, "u")
      .replace(/ñ/g, "n")
      .replace(/[^a-z0-9+#\s]/g, " "),
  );
}

function safeJsonStringify(value: unknown): string {
  try {
    return JSON.stringify(value);
  } catch {
    return "";
  }
}

function parseVertexPredictionVector(
  payload: unknown,
  dimension: number,
): number[] | null {
  const root = asRecord(payload);
  const predictions = root.predictions;
  if (!Array.isArray(predictions) || predictions.length === 0) return null;
  const first = asRecord(predictions[0]);
  const embeddings = asRecord(first.embeddings);
  const primary = toFiniteVector(embeddings.values, dimension);
  if (primary) return primary;
  const secondary = toFiniteVector(first.values, dimension);
  if (secondary) return secondary;
  return null;
}

async function requestVertexEmbedding({
  text,
  taskType,
  dimension,
}: {
  text: string;
  taskType: string;
  dimension: number;
}): Promise<number[]> {
  const auth = new GoogleAuth({
    scopes: [GOOGLE_CLOUD_SCOPE],
  });
  const projectId = await auth.getProjectId();
  if (!projectId) {
    throw new Error("Unable to resolve Google Cloud project ID.");
  }

  const location = asTrimmedString(process.env.VERTEX_AI_LOCATION) || DEFAULT_VERTEX_LOCATION;
  const model = asTrimmedString(process.env.VERTEX_AI_EMBEDDING_MODEL) || DEFAULT_VERTEX_MODEL;
  const endpoint =
    `https://${location}-aiplatform.googleapis.com/v1/projects/${projectId}` +
    `/locations/${location}/publishers/google/models/${model}:predict`;

  const client = await auth.getClient();
  const token = await client.getAccessToken();
  const accessToken = asTrimmedString(token.token ?? token);
  if (!accessToken) {
    throw new Error("Unable to acquire Google Cloud access token.");
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: safeJsonStringify({
      instances: [{
        task_type: taskType,
        content: text,
      }],
      parameters: {
        outputDimensionality: dimension,
      },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Vertex AI embedding request failed (${response.status}): ${body.slice(0, 400)}`);
  }

  const payload = await response.json();
  const vector = parseVertexPredictionVector(payload, dimension);
  if (!vector) {
    throw new Error("Vertex AI returned an invalid embedding payload.");
  }
  return vector;
}

export function hashText(text: string): string {
  return createHash("sha256").update(compactWhitespace(text)).digest("hex");
}

export function generateDeterministicEmbedding(
  text: string,
  dimensionInput?: number,
): number[] {
  const dimension = asFiniteDimension(dimensionInput);
  const normalized = normalizeForHashing(text);
  const vector = Array.from({ length: dimension }, () => 0);
  if (!normalized) return vector;

  const tokens = normalized.split(" ").filter(Boolean);
  if (tokens.length === 0) return vector;

  for (const token of tokens) {
    const index = hashToIndex(token, dimension);
    const tokenWeight = Math.min(3, 1 + (token.length / 12));
    vector[index] += tokenWeight;

    if (token.length > 5) {
      const prefix = token.slice(0, 4);
      const suffix = token.slice(-4);
      vector[hashToIndex(prefix, dimension)] += 0.3;
      vector[hashToIndex(suffix, dimension)] += 0.3;
    }
  }

  return l2Normalize(vector);
}

export async function generateEmbedding(
  input: GenerateEmbeddingInput,
): Promise<EmbeddingResult> {
  const text = compactWhitespace(input.text);
  const dimension = asFiniteDimension(
    input.outputDimensionality ?? process.env.EMBEDDING_VECTOR_DIMENSION,
  );
  const requestedTaskType = asTrimmedString(input.taskType).toUpperCase();
  const taskType = TASK_TYPE_SET.has(requestedTaskType)
    ? requestedTaskType
    : "SEMANTIC_SIMILARITY";

  if (!text) {
    return {
      vector: Array.from({ length: dimension }, () => 0),
      metadata: {
        provider: "fallback_hashing",
        model: "deterministic_hashing",
        version: "v1",
        dimension,
        source: "fallback_hashing",
      },
    };
  }

  const disableVertex = asTrimmedString(process.env.DISABLE_VERTEX_EMBEDDINGS) === "1";
  if (disableVertex) {
    return {
      vector: generateDeterministicEmbedding(text, dimension),
      metadata: {
        provider: "fallback_hashing",
        model: "deterministic_hashing",
        version: "v1",
        dimension,
        source: "fallback_hashing",
      },
    };
  }

  try {
    const vector = await requestVertexEmbedding({
      text,
      taskType,
      dimension,
    });

    const model = asTrimmedString(process.env.VERTEX_AI_EMBEDDING_MODEL) || DEFAULT_VERTEX_MODEL;
    return {
      vector,
      metadata: {
        provider: "vertex_ai",
        model,
        version: "v1",
        dimension: vector.length,
        source: "vertex_ai",
      },
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      vector: generateDeterministicEmbedding(text, dimension),
      metadata: {
        provider: "fallback_hashing",
        model: "deterministic_hashing",
        version: "v1",
        dimension,
        source: "fallback_hashing",
        lastError: errorMessage,
      },
    };
  }
}
