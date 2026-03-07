import * as crypto from "crypto";
import { writeAuditLog } from "../../../utils/auditLog";

export type JsonRecord = Record<string, unknown>;

export const SIGNATURE_REQUEST_TTL_DAYS = 7;
export const SIGNABLE_STATUSES = new Set(["offered", "accepted_pending_signature"]);

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

export function sha256Hex(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

export function nowPlusDays(days: number): Date {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
}

export async function logAuditEntry({
  action,
  actorUid,
  actorRole,
  targetType,
  targetId,
  companyId,
  metadata,
}: {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  companyId?: string | null;
  metadata: JsonRecord;
}): Promise<void> {
  await writeAuditLog({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: companyId ?? null,
    metadata,
  });
}

export function buildOfferDocumentHash({
  applicationId,
  candidateUid,
  companyUid,
  jobOfferId,
  offer,
}: {
  applicationId: string;
  candidateUid: string;
  companyUid: string;
  jobOfferId: string;
  offer: JsonRecord;
}): string {
  const canonicalPayload = {
    applicationId,
    candidateUid,
    companyUid,
    jobOfferId,
    title: asTrimmedString(offer.title),
    salaryMin: asTrimmedString(offer.salary_min ?? offer.salaryMin),
    salaryMax: asTrimmedString(offer.salary_max ?? offer.salaryMax),
    salaryCurrency: asTrimmedString(offer.salary_currency ?? offer.salaryCurrency),
    salaryPeriod: asTrimmedString(offer.salary_period ?? offer.salaryPeriod),
    contractType: asTrimmedString(offer.contract_type ?? offer.contractType),
    generatedAt: new Date().toISOString().slice(0, 10),
  };
  return sha256Hex(JSON.stringify(canonicalPayload));
}
