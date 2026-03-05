export type JsonRecord = Record<string, unknown>;

export const ALLOWED_REVIEW_ROLES = new Set([
  "admin",
  "recruiter",
  "hiring_manager",
  "external_evaluator",
]);

export const WEIGHTS = {
  semanticWeight: 0.6,
  skillsWeight: 0.25,
  locationWeight: 0.1,
  experienceWeight: 0.05,
} as const;

export function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

export function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

export function asFiniteNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function clamp01(value: number): number {
  if (!Number.isFinite(value) || isNaN(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export function toScore100(value: number): number {
  return Math.round(clamp01(value) * 100);
}

export function normalizeToken(value: unknown): string {
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

export function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asTrimmedString(item))
    .filter((item) => item.length > 0);
}

export function readSkillNames(value: unknown): string[] {
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

export function parseVector(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  const result: number[] = [];
  for (const item of value) {
    const parsed = Number(item);
    if (!Number.isFinite(parsed)) continue;
    result.push(parsed);
  }
  return result;
}

export function randomId(prefix: string): string {
  const random = Math.random().toString(16).slice(2, 10);
  return `${prefix}_${Date.now()}_${random}`;
}

export function buildSkillCoverage({
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

export function buildLocationScore({
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

export function parseDate(value: unknown): Date | null {
  const raw = asTrimmedString(value);
  if (!raw) return null;
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed;
}

export function estimateExperienceYears(curriculumData: JsonRecord): number {
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

export function buildExperienceScore({
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
