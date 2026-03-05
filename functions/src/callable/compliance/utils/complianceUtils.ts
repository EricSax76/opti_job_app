export const REQUEST_TYPES = [
  "access",
  "rectification",
  "deletion",
  "limitation",
  "portability",
  "opposition",
  "aiExplanation",
  "salaryComparison",
] as const;
export const REQUEST_TYPES_SET = new Set<string>(REQUEST_TYPES);

export const PROCESS_STATUSES = [
  "pending",
  "processing",
  "completed",
  "denied",
] as const;
export const PROCESS_STATUSES_SET = new Set<string>(PROCESS_STATUSES);

export const FINALIST_STATUSES = new Set([
  "offered",
  "hired",
  "interviewing",
  "finalist",
]);

export function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

export function asRecord(value: unknown): Record<string, unknown> {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as Record<string, unknown>;
}

export function asOptionalNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function normalizeRequestType(value: unknown): string {
  const raw = asTrimmedString(value);
  if (!raw) return "";
  const compact = raw.replace(/[_-\s]/g, "").toLowerCase();
  if (compact === "aiexplanation") return "aiExplanation";
  if (compact === "salarycomparison") return "salaryComparison";
  if (compact === "access") return "access";
  if (compact === "rectification") return "rectification";
  if (compact === "deletion") return "deletion";
  if (compact === "limitation") return "limitation";
  if (compact === "portability") return "portability";
  if (compact === "opposition") return "opposition";
  return raw;
}

export function normalizeProcessStatus(value: unknown): string {
  const raw = asTrimmedString(value).toLowerCase();
  if (raw === "process" || raw === "in_progress") return "processing";
  if (raw === "done") return "completed";
  return raw;
}

export function normalizeCandidateStatus(value: unknown): string {
  return asTrimmedString(value).toLowerCase();
}

export function normalizeRoleKey(roleOrTitle: string): string {
  return roleOrTitle
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/\s+/g, "_")
    .slice(0, 80);
}

export function ttlDate(days: number): Date {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
}
