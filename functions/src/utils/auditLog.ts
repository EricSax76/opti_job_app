import * as admin from "firebase-admin";
import {
  asPlainObjectOrEmpty,
  assertCamelCaseKeys,
} from "./contractConventions";

type JsonRecord = Record<string, unknown>;

const AUDIT_SCHEMA_VERSION = "2026.03";

function asTrimmedString(value: unknown): string {
  if (value == null) return "";
  return String(value).trim();
}

function toCanonicalAction(action: string): string {
  const withSnakeBoundaries = action
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/[^A-Za-z0-9]+/g, "_");
  return withSnakeBoundaries
    .toLowerCase()
    .replace(/^_+|_+$/g, "")
    .replace(/_+/g, "_");
}

function normalizeMetadata(metadata: unknown): JsonRecord {
  const normalized = asPlainObjectOrEmpty(metadata);
  assertCamelCaseKeys(normalized, {
    path: "audit.metadata",
    deep: true,
  });
  return normalized;
}

function normalizeExtraFields(extraFields: unknown): JsonRecord {
  const normalized = asPlainObjectOrEmpty(extraFields);
  assertCamelCaseKeys(normalized, {
    path: "audit.extraFields",
    deep: true,
  });
  return normalized;
}

type FirestoreTimestampLike =
  | admin.firestore.FieldValue
  | admin.firestore.Timestamp;

export interface WriteAuditLogInput {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  companyId?: string | null;
  metadata?: JsonRecord;
  extraFields?: JsonRecord;
  timestamp?: FirestoreTimestampLike;
}

const RESERVED_AUDIT_KEYS = new Set<string>([
  "action",
  "actionCanonical",
  "actorUid",
  "actorRole",
  "targetType",
  "targetId",
  "companyId",
  "metadata",
  "timestamp",
  "schemaVersion",
]);

function assertRequiredField(name: string, value: string): void {
  if (!value) {
    throw new Error(`[audit] ${name} is required.`);
  }
}

function assertNoReservedExtraField(extraFieldKey: string): void {
  if (RESERVED_AUDIT_KEYS.has(extraFieldKey)) {
    throw new Error(
      `[audit] extraFields cannot override reserved key "${extraFieldKey}".`,
    );
  }
}

export function buildAuditLogRecord(
  input: WriteAuditLogInput,
  forcedTimestamp?: FirestoreTimestampLike,
): JsonRecord {
  const action = asTrimmedString(input.action);
  const actorUid = asTrimmedString(input.actorUid);
  const actorRole = asTrimmedString(input.actorRole);
  const targetType = asTrimmedString(input.targetType);
  const targetId = asTrimmedString(input.targetId);
  const companyId = asTrimmedString(input.companyId);

  assertRequiredField("action", action);
  assertRequiredField("actorUid", actorUid);
  assertRequiredField("actorRole", actorRole);
  assertRequiredField("targetType", targetType);
  assertRequiredField("targetId", targetId);

  const metadata = normalizeMetadata(input.metadata);
  const extraFields = normalizeExtraFields(input.extraFields);
  for (const key of Object.keys(extraFields)) {
    assertNoReservedExtraField(key);
  }

  return {
    action,
    actionCanonical: toCanonicalAction(action),
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: companyId || null,
    metadata,
    schemaVersion: AUDIT_SCHEMA_VERSION,
    ...extraFields,
    timestamp:
      forcedTimestamp ??
      input.timestamp ??
      admin.firestore.FieldValue.serverTimestamp(),
  };
}

export async function writeAuditLog(input: WriteAuditLogInput): Promise<void> {
  const payload = buildAuditLogRecord(input);
  await admin.firestore().collection("auditLogs").add(payload);
}
