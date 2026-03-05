import { createHash } from "crypto";
import { GoogleAuth } from "google-auth-library";

type JsonRecord = Record<string, unknown>;

const DEFAULT_EMBEDDING_DIMENSION = 256;
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

function compactWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
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

function hashToIndex(token: string, dimension: number): number {
  const digest = createHash("sha256").update(token).digest();
  const seed = digest.readUInt32BE(0);
  return seed % dimension;
}

function l2Normalize(values: number[]): number[] {
  const norm = Math.sqrt(values.reduce((sum, value) => sum + (value * value), 0));
  if (!Number.isFinite(norm) || norm <= 0) return values.map(() => 0);
  return values.map((value) => value / norm);
}

function asFiniteDimension(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.max(8, Math.min(3072, Math.floor(value)));
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_EMBEDDING_DIMENSION;
  }
  return Math.max(8, Math.min(3072, Math.floor(parsed)));
}

function toFiniteVector(values: unknown, dimension: number): number[] | null {
  if (!Array.isArray(values) || values.length === 0) return null;
  const vector: number[] = [];
  for (const item of values) {
    const num = Number(item);
    if (!Number.isFinite(num)) continue;
    vector.push(num);
  }
  if (vector.length === 0) return null;
  if (vector.length === dimension) return l2Normalize(vector);
  if (vector.length > dimension) return l2Normalize(vector.slice(0, dimension));

  const padded = [...vector];
  while (padded.length < dimension) padded.push(0);
  return l2Normalize(padded);
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

export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length === 0 || b.length === 0) return 0;
  const length = Math.min(a.length, b.length);
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let index = 0; index < length; index += 1) {
    const av = Number(a[index]);
    const bv = Number(b[index]);
    if (!Number.isFinite(av) || !Number.isFinite(bv)) continue;
    dot += av * bv;
    normA += av * av;
    normB += bv * bv;
  }
  if (normA <= 0 || normB <= 0) return 0;
  const cosine = dot / Math.sqrt(normA * normB);
  if (!Number.isFinite(cosine)) return 0;
  return Math.max(-1, Math.min(1, cosine));
}

export function cosineScore01(a: number[], b: number[]): number {
  const cosine = cosineSimilarity(a, b);
  return Math.max(0, Math.min(1, (cosine + 1) / 2));
}

function readSkillNames(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const names: string[] = [];
  for (const item of value) {
    if (typeof item === "string") {
      const normalized = item.trim();
      if (normalized) names.push(normalized);
      continue;
    }
    if (item && typeof item === "object") {
      const row = item as Record<string, unknown>;
      const normalized = asTrimmedString(row.name ?? row.skillName ?? row.value);
      if (normalized) names.push(normalized);
    }
  }
  return names;
}

export function buildCandidateEmbeddingText({
  candidate,
  curriculum,
}: {
  candidate: unknown;
  curriculum: unknown;
}): string {
  const candidateData = asRecord(candidate);
  const curriculumData = asRecord(curriculum);

  const candidateSkills = [
    ...readSkillNames(candidateData.skills),
    ...readSkillNames(curriculumData.skills),
    ...readSkillNames(curriculumData.structuredSkills),
  ];

  const experienceRows = Array.isArray(curriculumData.experience)
    ? curriculumData.experience
    : [];
  const educationRows = Array.isArray(curriculumData.education)
    ? curriculumData.education
    : [];
  const languageRows = Array.isArray(curriculumData.languages)
    ? curriculumData.languages
    : [];

  const experienceText = experienceRows
    .map((row) => {
      const item = asRecord(row);
      return [
        asTrimmedString(item.position),
        asTrimmedString(item.company),
        asTrimmedString(item.description),
      ].filter(Boolean).join(" - ");
    })
    .filter(Boolean)
    .join(" | ");

  const educationText = educationRows
    .map((row) => {
      const item = asRecord(row);
      return [
        asTrimmedString(item.degree),
        asTrimmedString(item.institution),
        asTrimmedString(item.field),
      ].filter(Boolean).join(" - ");
    })
    .filter(Boolean)
    .join(" | ");

  const languageText = languageRows
    .map((row) => {
      const item = asRecord(row);
      return [asTrimmedString(item.name), asTrimmedString(item.proficiency)]
        .filter(Boolean)
        .join(": ");
    })
    .filter(Boolean)
    .join(" | ");

  return compactWhitespace([
    asTrimmedString(candidateData.name),
    asTrimmedString(candidateData.title),
    asTrimmedString(candidateData.bio),
    asTrimmedString(candidateData.location),
    asTrimmedString(curriculumData.summary),
    candidateSkills.join(", "),
    experienceText,
    educationText,
    languageText,
  ].filter(Boolean).join("\n"));
}

export function buildJobOfferEmbeddingText(offer: unknown): string {
  const offerData = asRecord(offer);
  const requiredSkills = [
    ...asStringList(offerData.requiredSkills),
    ...asStringList(offerData.skills),
  ];
  const preferredSkills = asStringList(offerData.preferredSkills);
  const qualifications = asStringList(offerData.qualifications);

  return compactWhitespace([
    asTrimmedString(offerData.title),
    asTrimmedString(offerData.description),
    asTrimmedString(offerData.location),
    asTrimmedString(offerData.job_category ?? offerData.jobCategory),
    asTrimmedString(offerData.contract_type ?? offerData.contractType),
    asTrimmedString(offerData.work_schedule ?? offerData.workSchedule),
    `Required skills: ${requiredSkills.join(", ")}`,
    `Preferred skills: ${preferredSkills.join(", ")}`,
    `Qualifications: ${qualifications.join(", ")}`,
    `Experience years: ${asTrimmedString(offerData.experience_years ?? offerData.experienceYears)}`,
  ].filter(Boolean).join("\n"));
}

