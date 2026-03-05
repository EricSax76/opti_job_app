import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const SKILL_ALIASES: Record<string, string[]> = {
  flutter: ["flutter", "flutter framework"],
  dart: ["dart", "dartlang"],
  react: ["react", "reactjs", "react.js", "react js"],
  react_native: ["react native", "react-native"],
  typescript: ["typescript", "ts"],
  javascript: ["javascript", "js", "ecmascript"],
  nodejs: ["nodejs", "node js", "node.js", "node"],
  aws: ["aws", "amazon web services"],
  gcp: ["gcp", "google cloud", "google cloud platform"],
  azure: ["azure", "microsoft azure"],
  docker: ["docker", "containers", "containerization"],
  kubernetes: ["kubernetes", "k8s"],
  postgresql: ["postgresql", "postgres", "psql"],
  mysql: ["mysql"],
};

const ADJACENCY: Record<string, string[]> = {
  flutter: ["dart", "react_native"],
  react: ["react_native", "javascript", "typescript"],
  react_native: ["react", "flutter"],
  typescript: ["javascript", "nodejs"],
  javascript: ["typescript", "nodejs", "react"],
  nodejs: ["javascript", "typescript"],
  aws: ["gcp", "azure"],
  gcp: ["aws", "azure"],
  azure: ["aws", "gcp"],
  docker: ["kubernetes"],
  kubernetes: ["docker"],
  postgresql: ["mysql"],
  mysql: ["postgresql"],
};

const REQUIRED_WEIGHT = 1;
const REQUIRED_ADJACENT_WEIGHT = 0.72;
const PREFERRED_WEIGHT = 0.45;
const PREFERRED_ADJACENT_WEIGHT = 0.24;

function normalizeToken(value: unknown): string {
  const raw = String(value ?? "").trim().toLowerCase();
  if (!raw) return "";
  return raw
    .replace(/á/g, "a")
    .replace(/é/g, "e")
    .replace(/í/g, "i")
    .replace(/ó/g, "o")
    .replace(/ú/g, "u")
    .replace(/ü/g, "u")
    .replace(/ñ/g, "n")
    .replace(/[^a-z0-9+#\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function buildAliasLookup(): Map<string, string> {
  const lookup = new Map<string, string>();
  for (const [canonical, aliases] of Object.entries(SKILL_ALIASES)) {
    lookup.set(normalizeToken(canonical), canonical);
    for (const alias of aliases) {
      lookup.set(normalizeToken(alias), canonical);
    }
  }
  return lookup;
}

const ALIAS_LOOKUP = buildAliasLookup();

function canonicalize(value: unknown): string {
  const normalized = normalizeToken(value);
  if (!normalized) return "";
  return ALIAS_LOOKUP.get(normalized) ?? normalized;
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
      const normalized = String(row.name ?? row.skillName ?? "").trim();
      if (normalized) names.push(normalized);
    }
  }
  return names;
}

function findAdjacentCandidate(
  requiredCanonical: string,
  candidateByCanonical: Map<string, string[]>,
): string | null {
  const adjacent = ADJACENCY[requiredCanonical] ?? [];
  for (const adjacentCanonical of adjacent) {
    const matches = candidateByCanonical.get(adjacentCanonical);
    if (matches && matches.length > 0) {
      return matches[0];
    }
  }
  return null;
}

function toScore(earned: number, total: number): number {
  if (total <= 0) return 0;
  return Math.max(0, Math.min(100, Math.round((earned / total) * 100)));
}

export const matchCandidateWithSkills = functions.region("europe-west1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const applicationId = String(data?.applicationId ?? "").trim();
  const jobOfferId = String(data?.jobOfferId ?? "").trim();
  if (!applicationId || !jobOfferId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "applicationId and jobOfferId are required.",
    );
  }

  const db = admin.firestore();
  const [appDoc, offerDoc] = await Promise.all([
    db.collection("applications").doc(applicationId).get(),
    db.collection("jobOffers").doc(jobOfferId).get(),
  ]);
  if (!appDoc.exists || !offerDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Application or Job Offer not found.");
  }

  const app = appDoc.data() as Record<string, unknown>;
  const offer = offerDoc.data() as Record<string, unknown>;
  const curriculumId = String(app.curriculum_id ?? app.curriculumId ?? "").trim();
  const curriculumDoc = curriculumId
    ? await db.collection("curriculum").doc(curriculumId).get()
    : null;
  const curriculum = curriculumDoc?.exists
    ? (curriculumDoc.data() as Record<string, unknown>)
    : null;

  const candidateSkills = [
    ...readSkillNames(curriculum?.structuredSkills),
    ...readSkillNames(curriculum?.skills),
    ...readSkillNames(app.skills),
  ];
  const requiredSkills = [
    ...readSkillNames(offer.requiredSkills),
    ...readSkillNames(offer.skills),
  ];
  const preferredSkills = readSkillNames(offer.preferredSkills);

  const candidateByCanonical = new Map<string, string[]>();
  for (const skill of candidateSkills) {
    const canonical = canonicalize(skill);
    if (!canonical) continue;
    const list = candidateByCanonical.get(canonical) ?? [];
    list.push(skill);
    candidateByCanonical.set(canonical, list);
  }

  const matched = new Set<string>();
  const missing = new Set<string>();
  const adjacent = new Set<string>();
  const reasons: string[] = [];
  const recommendations: string[] = [];
  let totalWeight = 0;
  let earnedWeight = 0;

  for (const required of requiredSkills) {
    const canonical = canonicalize(required);
    if (!canonical) continue;
    totalWeight += REQUIRED_WEIGHT;
    if (candidateByCanonical.has(canonical)) {
      matched.add(required);
      earnedWeight += REQUIRED_WEIGHT;
      reasons.push(`Coincidencia exacta en requisito: ${required}.`);
      continue;
    }
    const adjacentSkill = findAdjacentCandidate(canonical, candidateByCanonical);
    if (adjacentSkill) {
      adjacent.add(`${required} ↔ ${adjacentSkill}`);
      earnedWeight += REQUIRED_ADJACENT_WEIGHT;
      reasons.push(`Cobertura adyacente en requisito: ${required} con ${adjacentSkill}.`);
      continue;
    }
    missing.add(required);
    recommendations.push(`Reforzar ${required}.`);
  }

  for (const preferred of preferredSkills) {
    const canonical = canonicalize(preferred);
    if (!canonical) continue;
    totalWeight += PREFERRED_WEIGHT;
    if (candidateByCanonical.has(canonical)) {
      matched.add(preferred);
      earnedWeight += PREFERRED_WEIGHT;
      continue;
    }
    const adjacentSkill = findAdjacentCandidate(canonical, candidateByCanonical);
    if (adjacentSkill) {
      adjacent.add(`${preferred} ↔ ${adjacentSkill}`);
      earnedWeight += PREFERRED_ADJACENT_WEIGHT;
    }
  }

  const score = toScore(earnedWeight, totalWeight);
  const explanation = [
    `Score calculado con matching semántico determinista (${score}/100).`,
    `Requisitos exactos: ${matched.size}, adyacentes: ${adjacent.size}, faltantes: ${missing.size}.`,
    "No se utiliza reconocimiento emocional ni biométrico.",
  ].join(" ");

  if (recommendations.length === 0) {
    recommendations.push("Programar entrevista técnica para validar profundidad en skills clave.");
  }

  const aiResult = {
    score,
    reasons,
    recommendations,
    explanation,
    skillsOverlap: {
      matched: [...matched],
      missing: [...missing],
      adjacent: [...adjacent],
    },
    modelVersion: "semantic-ranker-v1",
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await appDoc.ref.update({
    aiMatchResult: aiResult,
    match_score: score,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return aiResult;
});
