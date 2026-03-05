import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleAuth } from "google-auth-library";
import {
  buildCandidateEmbeddingText,
  buildJobOfferEmbeddingText,
  cosineScore01,
  generateEmbedding,
  hashText,
} from "../../utils/embeddings";
import { writeAiDecisionLog, writeAuditLog } from "../../utils/aiDecisionLogs";

type JsonRecord = Record<string, unknown>;

const ALLOWED_REVIEW_ROLES = new Set([
  "admin",
  "recruiter",
  "hiring_manager",
  "external_evaluator",
]);

const WEIGHTS = {
  semanticWeight: 0.6,
  skillsWeight: 0.25,
  locationWeight: 0.1,
  experienceWeight: 0.05,
} as const;

const GOOGLE_CLOUD_SCOPE = "https://www.googleapis.com/auth/cloud-platform";

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

function asFiniteNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function toScore100(value: number): number {
  return Math.round(clamp01(value) * 100);
}

function normalizeToken(value: unknown): string {
  const raw = asTrimmedString(value).toLowerCase();
  if (!raw) return "";
  return raw
    .replace(/[áàâä]/g, "a")
    .replace(/[éèêë]/g, "e")
    .replace(/[íìîï]/g, "i")
    .replace(/[óòôö]/g, "o")
    .replace(/[úùûü]/g, "u")
    .replace(/ñ/g, "n")
    .replace(/[^a-z0-9+#\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asTrimmedString(item))
    .filter((item) => item.length > 0);
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

function parseVector(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  const result: number[] = [];
  for (const item of value) {
    const parsed = Number(item);
    if (!Number.isFinite(parsed)) continue;
    result.push(parsed);
  }
  return result;
}

function randomId(prefix: string): string {
  const random = Math.random().toString(16).slice(2, 10);
  return `${prefix}_${Date.now()}_${random}`;
}

async function assertRecruiterAccess(
  db: FirebaseFirestore.Firestore,
  actorUid: string,
  companyId: string,
): Promise<"company" | "recruiter"> {
  if (actorUid === companyId) return "company";

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Solo la empresa o recruiters autorizados pueden revisar matching vectorial.",
    );
  }
  const recruiter = asRecord(recruiterDoc.data());
  const recruiterCompanyId = asTrimmedString(recruiter.companyId);
  const recruiterStatus = asTrimmedString(recruiter.status).toLowerCase();
  const recruiterRole = asTrimmedString(recruiter.role);

  if (
    recruiterCompanyId !== companyId ||
    recruiterStatus !== "active" ||
    !ALLOWED_REVIEW_ROLES.has(recruiterRole)
  ) {
    throw new HttpsError(
      "permission-denied",
      "Tu rol no tiene permisos para evaluar decisiones IA de esta empresa.",
    );
  }
  return "recruiter";
}

async function assertApplicationAccess({
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
  const scope = await assertRecruiterAccess(db, actorUid, companyId);
  return scope;
}

async function resolveCurriculumDoc({
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

async function ensureCandidateEmbedding({
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

async function ensureOfferEmbedding({
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

function buildSkillCoverage({
  candidateSkills,
  offerRequiredSkills,
  offerPreferredSkills,
}: {
  candidateSkills: string[];
  offerRequiredSkills: string[];
  offerPreferredSkills: string[];
}): {
  score: number;
  matchedRequired: string[];
  missingRequired: string[];
  matchedPreferred: string[];
} {
  const candidateSet = new Set(candidateSkills.map((skill) => normalizeToken(skill)).filter(Boolean));
  const required = offerRequiredSkills.map((skill) => normalizeToken(skill)).filter(Boolean);
  const preferred = offerPreferredSkills.map((skill) => normalizeToken(skill)).filter(Boolean);

  const matchedRequired = required.filter((skill) => candidateSet.has(skill));
  const missingRequired = required.filter((skill) => !candidateSet.has(skill));
  const matchedPreferred = preferred.filter((skill) => candidateSet.has(skill));

  const requiredScore = required.length > 0
    ? matchedRequired.length / required.length
    : 1;
  const preferredScore = preferred.length > 0
    ? matchedPreferred.length / preferred.length
    : 1;

  return {
    score: clamp01((requiredScore * 0.8) + (preferredScore * 0.2)),
    matchedRequired,
    missingRequired,
    matchedPreferred,
  };
}

function buildLocationScore({
  candidateLocation,
  offerLocation,
}: {
  candidateLocation: string;
  offerLocation: string;
}): number {
  const a = normalizeToken(candidateLocation);
  const b = normalizeToken(offerLocation);
  if (!a && !b) return 0.5;
  if (!a || !b) return 0.2;
  if (a === b) return 1;
  if (a.includes(b) || b.includes(a)) return 0.8;

  const aSet = new Set(a.split(" ").filter(Boolean));
  const bSet = new Set(b.split(" ").filter(Boolean));
  let overlap = 0;
  for (const token of aSet) {
    if (bSet.has(token)) overlap += 1;
  }
  if (overlap > 0) {
    return clamp01(0.45 + (overlap / Math.max(aSet.size, bSet.size)) * 0.4);
  }
  return 0.1;
}

function parseDate(value: unknown): Date | null {
  const raw = asTrimmedString(value);
  if (!raw) return null;
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

function estimateExperienceYears(curriculumData: JsonRecord): number {
  const experienceRows = Array.isArray(curriculumData.experience)
    ? curriculumData.experience
    : [];
  let totalMilliseconds = 0;

  for (const row of experienceRows) {
    const item = asRecord(row);
    const start = parseDate(item.start_date ?? item.startDate);
    if (!start) continue;

    const current = Boolean(item.current);
    const end = current
      ? new Date()
      : (parseDate(item.end_date ?? item.endDate) ?? new Date());

    if (end.getTime() <= start.getTime()) continue;
    totalMilliseconds += end.getTime() - start.getTime();
  }

  const years = totalMilliseconds / (1000 * 60 * 60 * 24 * 365.25);
  if (!Number.isFinite(years) || years < 0) return 0;
  return years;
}

function buildExperienceScore({
  candidateYears,
  requiredYears,
}: {
  candidateYears: number;
  requiredYears: number | null;
}): number {
  if (requiredYears == null || requiredYears <= 0) {
    if (candidateYears <= 0) return 0.5;
    return Math.min(1, 0.65 + (candidateYears / 12) * 0.35);
  }
  if (candidateYears <= 0) return 0;
  return clamp01(candidateYears / requiredYears);
}

interface NeighborResult {
  offerId: string;
  similarity: number;
  title: string;
}

function decodeFirestoreValue(value: unknown): unknown {
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
    const output: JsonRecord = {};
    for (const [key, typedValue] of Object.entries(fields)) {
      output[key] = decodeFirestoreValue(typedValue);
    }
    return output;
  }
  return null;
}

async function tryFirestoreVectorSearchRest({
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

async function tryFirestoreVectorSearch({
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

async function manualNeighborSearch({
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

export const matchCandidateVector = onCall({ region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const applicationId = asTrimmedString(request.data?.applicationId);
  const limit = Math.max(3, Math.min(25, Number(request.data?.limit ?? 8) || 8));
  if (!applicationId) {
    throw new HttpsError("invalid-argument", "applicationId es obligatorio.");
  }

  const requestId = asTrimmedString(request.data?.requestId) || randomId("req");
  const executionId = randomId("exec");
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
  const jobOfferId =
    asTrimmedString(appData.job_offer_id) ||
    asTrimmedString(appData.jobOfferId);

  if (!candidateUid || !companyId || !jobOfferId) {
    throw new HttpsError(
      "failed-precondition",
      "La candidatura no tiene candidate/company/jobOffer consistente.",
    );
  }

  const actorScope = await assertApplicationAccess({
    db,
    actorUid: request.auth.uid,
    candidateUid,
    companyId,
  });

  const [candidateDoc, offerDoc] = await Promise.all([
    db.collection("candidates").doc(candidateUid).get(),
    db.collection("jobOffers").doc(jobOfferId).get(),
  ]);
  if (!offerDoc.exists) {
    throw new HttpsError("not-found", "La oferta de la candidatura no existe.");
  }

  const candidateData = asRecord(candidateDoc.data());
  const offerData = asRecord(offerDoc.data());
  const curriculumId = asTrimmedString(appData.curriculum_id ?? appData.curriculumId);
  const curriculum = await resolveCurriculumDoc({
    db,
    candidateUid,
    curriculumId,
  });

  const [candidateEmbedding, offerEmbedding] = await Promise.all([
    ensureCandidateEmbedding({
      db,
      candidateUid,
      curriculumId: curriculum.curriculumId,
      candidateData,
      curriculumData: curriculum.data,
    }),
    ensureOfferEmbedding({
      offerRef: offerDoc.ref,
      offerData,
    }),
  ]);

  const vectorNeighborsFromFirestore = await tryFirestoreVectorSearch({
    db,
    queryVector: candidateEmbedding.vector,
    limit,
  });
  const vectorSearchMode = vectorNeighborsFromFirestore
    ? "firestore_vector_query"
    : "manual_cosine_fallback";
  const neighbors = vectorNeighborsFromFirestore ??
    await manualNeighborSearch({
      db,
      queryVector: candidateEmbedding.vector,
      limit,
    });

  const targetSimilarity = cosineScore01(
    candidateEmbedding.vector,
    offerEmbedding.vector,
  );
  const targetRank = neighbors.findIndex((item) => item.offerId === jobOfferId);

  const candidateSkills = [
    ...readSkillNames(candidateData.skills),
    ...readSkillNames(curriculum.data.skills),
    ...readSkillNames(curriculum.data.structuredSkills),
  ];
  const offerRequiredSkills = [
    ...asStringList(offerData.requiredSkills),
    ...asStringList(offerData.skills),
  ];
  const offerPreferredSkills = asStringList(offerData.preferredSkills);

  const skillCoverage = buildSkillCoverage({
    candidateSkills,
    offerRequiredSkills,
    offerPreferredSkills,
  });
  const candidateLocation =
    asTrimmedString(candidateData.location) ||
    asTrimmedString(asRecord(curriculum.data.personal_info).location);
  const offerLocation = [
    asTrimmedString(offerData.location),
    asTrimmedString(offerData.province_name ?? offerData.provinceName),
    asTrimmedString(offerData.municipality_name ?? offerData.municipalityName),
  ].filter(Boolean).join(" - ");
  const locationScore = buildLocationScore({
    candidateLocation,
    offerLocation,
  });
  const candidateExperienceYears = estimateExperienceYears(curriculum.data);
  const requiredYears = asFiniteNumber(
    offerData.experience_years ?? offerData.experienceYears,
  );
  const experienceScore = buildExperienceScore({
    candidateYears: candidateExperienceYears,
    requiredYears,
  });

  const semanticScore = targetSimilarity;
  const finalScore = clamp01(
    (semanticScore * WEIGHTS.semanticWeight) +
    (skillCoverage.score * WEIGHTS.skillsWeight) +
    (locationScore * WEIGHTS.locationWeight) +
    (experienceScore * WEIGHTS.experienceWeight),
  );

  const semanticScore100 = toScore100(semanticScore);
  const skillsScore100 = toScore100(skillCoverage.score);
  const locationScore100 = toScore100(locationScore);
  const experienceScore100 = toScore100(experienceScore);
  const finalScore100 = toScore100(finalScore);
  const comparisonDelta = finalScore100 - skillsScore100;

  const reasons: string[] = [];
  reasons.push(
    `Similitud semántica CV-oferta: ${semanticScore100}/100 (${vectorSearchMode}).`,
  );
  reasons.push(
    `Cobertura de skills: ${skillCoverage.matchedRequired.length}/${offerRequiredSkills.length || 1} requeridas.`,
  );
  if (candidateLocation && offerLocation) {
    reasons.push(`Afinidad geográfica estimada: ${locationScore100}/100.`);
  }
  reasons.push(`Ajuste por experiencia: ${experienceScore100}/100.`);

  const recommendations: string[] = [];
  for (const missing of skillCoverage.missingRequired.slice(0, 3)) {
    recommendations.push(`Reforzar skill requerida: ${missing}.`);
  }
  if (recommendations.length === 0) {
    recommendations.push("Continuar con entrevista técnica para validar profundidad.");
  }

  const explanation =
    `Score vectorial final ${finalScore100}/100 con pesos ` +
    `semantic=${WEIGHTS.semanticWeight}, skills=${WEIGHTS.skillsWeight}, ` +
    `location=${WEIGHTS.locationWeight}, experience=${WEIGHTS.experienceWeight}. ` +
    `Sin uso de reconocimiento emocional ni biométrico.`;

  const now = admin.firestore.FieldValue.serverTimestamp();
  const result = {
    score: finalScore100,
    semanticScore: semanticScore100,
    componentScores: {
      semantic: semanticScore100,
      skills: skillsScore100,
      location: locationScore100,
      experience: experienceScore100,
    },
    weights: WEIGHTS,
    reasons,
    recommendations,
    explanation,
    comparative: {
      skillsOnlyScore: skillsScore100,
      deltaVsSkillsOnly: comparisonDelta,
    },
    vectorSearch: {
      mode: vectorSearchMode,
      targetOfferRank: targetRank >= 0 ? (targetRank + 1) : null,
      neighbors: neighbors.slice(0, 5).map((item) => ({
        offerId: item.offerId,
        title: item.title,
        similarity: toScore100(item.similarity),
      })),
    },
    featuresConsidered: {
      candidateSkills: candidateSkills.length,
      requiredSkills: offerRequiredSkills.length,
      preferredSkills: offerPreferredSkills.length,
      matchedRequiredSkills: skillCoverage.matchedRequired,
      missingRequiredSkills: skillCoverage.missingRequired,
      matchedPreferredSkills: skillCoverage.matchedPreferred,
      candidateLocation,
      offerLocation,
      candidateExperienceYears: Number(candidateExperienceYears.toFixed(2)),
      requiredExperienceYears: requiredYears,
    },
    modelVersion: "vector-matcher-v1",
    model: {
      provider: asTrimmedString(offerEmbedding.model.provider) || asTrimmedString(candidateEmbedding.model.provider) || "unknown",
      version: "v1",
      embeddingModel: asTrimmedString(offerEmbedding.model.model) || asTrimmedString(candidateEmbedding.model.model) || "unknown",
      candidateEmbeddingSource: candidateEmbedding.source,
      offerEmbeddingSource: offerEmbedding.source,
    },
    requestId,
    executionId,
    generatedAt: new Date().toISOString(),
  };

  await appDoc.ref.set({
    aiMatchResult: {
      ...result,
      generatedAt: now,
      reviewedByHuman: false,
    },
    match_score: finalScore100,
    updated_at: now,
    updatedAt: now,
  }, { merge: true });

  const decisionLogId = await writeAiDecisionLog({
    applicationId,
    companyId,
    candidateUid,
    jobOfferId,
    decisionType: "vector_match",
    decisionStatus: "generated",
    score: finalScore100,
    weights: WEIGHTS,
    model: {
      provider: asTrimmedString(result.model.provider) || "unknown",
      model: asTrimmedString(result.model.embeddingModel) || "unknown",
      version: asTrimmedString(result.model.version) || "v1",
      source: asTrimmedString(result.model.offerEmbeddingSource) || "unknown",
    },
    requestId,
    executionId,
    features: result.featuresConsidered as unknown as JsonRecord,
    metadata: {
      vectorSearchMode,
      targetOfferRank: targetRank >= 0 ? (targetRank + 1) : null,
      neighbors: result.vectorSearch.neighbors,
      candidateEmbeddingHash: candidateEmbedding.textHash,
      offerEmbeddingHash: offerEmbedding.textHash,
      comparative: result.comparative,
    },
    actorUid: request.auth.uid,
    actorRole: actorScope,
  });

  await Promise.all([
    appDoc.ref.set({
      aiMatchResult: {
        decisionLogId,
      },
    }, { merge: true }),
    writeAuditLog({
      action: "ai_vector_match_generated",
      actorUid: request.auth.uid,
      actorRole: actorScope,
      targetType: "application",
      targetId: applicationId,
      companyId,
      metadata: {
        requestId,
        executionId,
        decisionLogId,
        score: finalScore100,
        vectorSearchMode,
      },
    }),
  ]);

  return {
    applicationId,
    decisionLogId,
    ...result,
  };
});
