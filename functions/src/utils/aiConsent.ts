import * as admin from "firebase-admin";
import * as crypto from "crypto";

export const AI_CONSENT_SCOPES = ["ai_interview", "ai_test"] as const;
export type AiConsentScope = (typeof AI_CONSENT_SCOPES)[number];

type JsonRecord = Record<string, unknown>;

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function asRecord(value: unknown): JsonRecord {
  if (value === null || value === undefined) return {};
  if (typeof value !== "object" || Array.isArray(value)) return {};
  return value as JsonRecord;
}

function asTimestamp(value: unknown): admin.firestore.Timestamp | null {
  if (value instanceof admin.firestore.Timestamp) return value;
  return null;
}

export function normalizeAiConsentScopes(input: unknown): AiConsentScope[] {
  if (!Array.isArray(input)) return [];
  const allowed = new Set<string>(AI_CONSENT_SCOPES);
  const normalized = new Set<AiConsentScope>();
  for (const raw of input) {
    const scope = asTrimmedString(raw).toLowerCase();
    if (!allowed.has(scope)) continue;
    normalized.add(scope as AiConsentScope);
  }
  return Array.from(normalized).sort();
}

export function normalizeConsentTextVersion(input: unknown): string {
  return asTrimmedString(input);
}

export function normalizeConsentText(input: unknown): string {
  return asTrimmedString(input).replace(/\s+/g, " ").trim();
}

export function sha256Hex(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

export function buildCanonicalAiConsentPayload({
  candidateUid,
  companyId,
  scope,
  consentTextVersion,
  consentText,
}: {
  candidateUid: string;
  companyId: string;
  scope: AiConsentScope[];
  consentTextVersion: string;
  consentText: string;
}): JsonRecord {
  return {
    candidateUid: asTrimmedString(candidateUid),
    companyId: asTrimmedString(companyId),
    scope: [...scope].sort(),
    consentTextVersion: normalizeConsentTextVersion(consentTextVersion),
    consentText: normalizeConsentText(consentText),
  };
}

export function computeAiConsentHash(payload: JsonRecord): string {
  return sha256Hex(JSON.stringify(payload));
}

function toCanonicalPayloadFromRecord(record: JsonRecord): JsonRecord {
  const payload = asRecord(record.consentHashPayload);
  const fallbackScope = normalizeAiConsentScopes(record.scope);
  const scope = normalizeAiConsentScopes(payload.scope);

  return buildCanonicalAiConsentPayload({
    candidateUid: asTrimmedString(payload.candidateUid || record.candidateUid),
    companyId: asTrimmedString(payload.companyId || record.companyId),
    scope: scope.length > 0 ? scope : fallbackScope,
    consentTextVersion: normalizeConsentTextVersion(
      payload.consentTextVersion ||
        record.consentTextVersion ||
        record.informationNoticeVersion,
    ),
    consentText: normalizeConsentText(
      payload.consentText ||
        record.consentTextSnapshot ||
        record.consentText ||
        "",
    ),
  });
}

function isHashVerified(record: JsonRecord): boolean {
  const hash = asTrimmedString(record.consentHash);
  if (!hash) return false;
  const canonicalPayload = toCanonicalPayloadFromRecord(record);
  const recomputed = computeAiConsentHash(canonicalPayload);
  return recomputed === hash;
}

export function hasValidAiConsentRecord({
  record,
  companyId,
  requiredScope,
  now,
}: {
  record: JsonRecord;
  companyId: string;
  requiredScope: AiConsentScope;
  now: Date;
}): boolean {
  const normalizedCompanyId = asTrimmedString(companyId);
  if (!normalizedCompanyId) return false;

  const recordCompanyId = asTrimmedString(record.companyId);
  if (!recordCompanyId || recordCompanyId !== normalizedCompanyId) return false;

  const granted = record.granted === true;
  if (!granted) return false;

  const scopes = normalizeAiConsentScopes(record.scope);
  if (!scopes.includes(requiredScope)) return false;

  const consentTextVersion = normalizeConsentTextVersion(
    record.consentTextVersion || record.informationNoticeVersion,
  );
  if (!consentTextVersion) return false;

  const grantedAt = asTimestamp(record.grantedAt);
  if (grantedAt == null) return false;

  const revokedAt = asTimestamp(record.revokedAt);
  if (revokedAt != null) return false;

  const expiresAt = asTimestamp(record.expiresAt);
  if (expiresAt != null && expiresAt.toDate().getTime() <= now.getTime()) {
    return false;
  }

  if (!isHashVerified(record)) return false;

  return true;
}

export function grantedAtMillis(record: JsonRecord): number {
  const grantedAt = asTimestamp(record.grantedAt);
  return grantedAt?.toMillis() ?? 0;
}

