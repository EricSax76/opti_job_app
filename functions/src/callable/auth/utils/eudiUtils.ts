import * as crypto from "crypto";

export type JsonRecord = Record<string, unknown>;

export const DEFAULT_PROOF_SCHEMA_VERSION = "2026.1";
export const EUDI_PROOF_SCHEMA_VERSION = "2026.1";

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

export function normalizeEmail(value: unknown): string {
  return asTrimmedString(value).toLowerCase();
}

export function normalizeIsoDate(value: unknown): string | null {
  const raw = asTrimmedString(value);
  if (!raw) return null;
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString();
}

export function sanitizeDocId(raw: string): string {
  const normalized = raw
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 110);
  return normalized || `cred-${Date.now()}`;
}

export function sha256Hex(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

export function randomHex(bytes = 24): string {
  return crypto.randomBytes(bytes).toString("hex");
}

export function nowPlusMinutes(minutes: number): Date {
  return new Date(Date.now() + minutes * 60 * 1000);
}

export function resolveExpectedAudience(
  data: unknown,
  fallbackAudience: string,
): string {
  const payload = asRecord(data);
  const requestedAudience = asTrimmedString(payload.expectedAudience);
  if (requestedAudience) return requestedAudience;
  return fallbackAudience;
}
