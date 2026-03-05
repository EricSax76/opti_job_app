import * as admin from 'firebase-admin';

export type JsonRecord = Record<string, unknown>;

export function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value).trim();
}

export function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

export function asRecordNullable(value: unknown): JsonRecord | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'object' || Array.isArray(value)) return null;
  return value as JsonRecord;
}

export function toNullableString(value: unknown): string | null {
  const normalized = asTrimmedString(value);
  return normalized.length > 0 ? normalized : null;
}

export function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asTrimmedString(item))
    .filter((item) => item.length > 0);
}

export function toTimestamp(value: unknown): admin.firestore.Timestamp | null {
  if (value instanceof admin.firestore.Timestamp) return value;
  if (value instanceof Date) return admin.firestore.Timestamp.fromDate(value);
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    if (!Number.isNaN(parsed)) {
      return admin.firestore.Timestamp.fromMillis(parsed);
    }
  }
  return null;
}

export function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => asTrimmedString(item))
    .filter((item) => item.length > 0);
}

export function compactWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
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
