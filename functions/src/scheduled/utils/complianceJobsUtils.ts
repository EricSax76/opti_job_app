import * as admin from 'firebase-admin';

export const THREE_YEARS_MS = 3 * 365 * 24 * 60 * 60 * 1000;
export const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
export const CONSENT_RENEWAL_WINDOW_DAYS = 30;
export const MAX_DOCS_PER_QUERY = 250;
export const BATCH_WRITE_LIMIT = 450;
export const BLOCKED_ARCHIVE_RETENTION_DAYS = 3 * 365;

export type JsonRecord = Record<string, unknown>;

export interface StorageMoveResult {
  sourcePath: string;
  archivePath: string;
}

export interface ArchiveTransferRecord {
  sourceRef: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;
  sourceCollection: string;
  sourceDocumentId: string;
  sourcePath: string;
  companyId: string | null;
  candidateUid: string | null;
  payload: FirebaseFirestore.DocumentData;
  reason: string;
  movedStorage: StorageMoveResult[];
}

export interface ArchiveTransferStats {
  archivedCount: number;
  skippedLegalHoldCount: number;
}

export interface VideoInterviewTtlStats {
  ttlAssignedCount: number;
  expiredStillPresentCount: number;
  skippedLegalHoldCount: number;
  scannedCount: number;
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

export function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value).trim();
}

export function asRecord(value: unknown): JsonRecord | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'object' || Array.isArray(value)) return null;
  return value as JsonRecord;
}

export function toNullableString(value: unknown): string | null {
  const normalized = asTrimmedString(value);
  return normalized.length > 0 ? normalized : null;
}

export function readCompanyId(data: JsonRecord): string | null {
  return toNullableString(data.company_uid ?? data.companyUid ?? data.companyId ?? data.owner_uid);
}

export function readCandidateUid(data: JsonRecord): string | null {
  return toNullableString(data.candidate_uid ?? data.candidateUid ?? data.uid);
}

export function archiveBlockedUntil(now: admin.firestore.Timestamp): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(
    now.toMillis() + (BLOCKED_ARCHIVE_RETENTION_DAYS * 24 * 60 * 60 * 1000),
  );
}

export function isLegalHoldActive(value: unknown): boolean {
  if (value === true) return true;
  if (value === false || value == null) return false;
  const legalHold = asRecord(value);
  if (legalHold == null) return false;
  if (legalHold.active === true) return true;
  const status = asTrimmedString(legalHold.status).toLowerCase();
  return ['active', 'on', 'enabled', 'legal_hold'].includes(status);
}

export function extractStoragePath(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const value = raw.trim();
  if (!value) return null;

  if (!value.startsWith('http') && !value.startsWith('gs://')) {
    return value;
  }

  if (value.startsWith('gs://')) {
    const withoutPrefix = value.replace('gs://', '');
    const firstSlash = withoutPrefix.indexOf('/');
    if (firstSlash < 0) return null;
    return withoutPrefix.substring(firstSlash + 1);
  }

  try {
    const url = new URL(value);
    const marker = '/o/';
    const markerIndex = url.pathname.indexOf(marker);
    if (markerIndex < 0) return null;
    const encodedPath = url.pathname.substring(markerIndex + marker.length);
    return decodeURIComponent(encodedPath);
  } catch (_) {
    return null;
  }
}

export async function moveStorageObjectToBlockedArchive(
  path: string,
  archivePrefix: string,
): Promise<StorageMoveResult | null> {
  const normalizedPath = extractStoragePath(path);
  if (normalizedPath == null) return null;

  const sourcePath = normalizedPath;
  const sanitizedSourcePath = normalizedPath.replace(/\//g, '__');
  const archivePath = `blockedArchive/storage/${archivePrefix}/${Date.now()}_${sanitizedSourcePath}`;
  const bucket = admin.storage().bucket();
  const sourceFile = bucket.file(sourcePath);
  const archiveFile = bucket.file(archivePath);

  try {
    const [exists] = await sourceFile.exists();
    if (!exists) return null;

    await sourceFile.copy(archiveFile);
    await sourceFile.delete();
    return { sourcePath, archivePath };
  } catch (error) {
    const err = error as { code?: number; message?: string };
    if (err?.code === 404 || err?.message?.toLowerCase().includes('no such object')) {
      return null;
    }
    throw error;
  }
}

export async function deleteStorageObjectIfExists(path: string): Promise<void> {
  if (!path.trim()) return;

  try {
    await admin.storage().bucket().file(path).delete();
  } catch (error) {
    // Ignorar objetos ya eliminados
    const err = error as { code?: number; message?: string };
    if (err?.code === 404 || err?.message?.toLowerCase().includes('no such object')) {
      return;
    }
    throw error;
  }
}

export async function commitArchiveTransfers(
  transfers: ArchiveTransferRecord[],
  now: admin.firestore.Timestamp,
): Promise<number> {
  if (transfers.length === 0) return 0;
  const db = admin.firestore();
  let batch = db.batch();
  let pendingWrites = 0;
  let archived = 0;

  for (const transfer of transfers) {
    const archiveRef = db.collection('blockedArchive').doc();
    const auditRef = db.collection('auditLogs').doc();

    batch.set(archiveRef, {
      id: archiveRef.id,
      sourceCollection: transfer.sourceCollection,
      sourceDocumentId: transfer.sourceDocumentId,
      sourcePath: transfer.sourcePath,
      companyId: transfer.companyId,
      candidateUid: transfer.candidateUid,
      reason: transfer.reason,
      legalHold: false,
      blockedUntil: archiveBlockedUntil(now),
      archivedAt: now,
      archivedBy: 'system:blockExpiredData',
      movedStorage: transfer.movedStorage,
      payload: transfer.payload,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    batch.delete(transfer.sourceRef);
    batch.set(auditRef, {
      action: 'blocked_archive_transfer',
      actorUid: 'system',
      actorRole: 'system',
      targetType: transfer.sourceCollection,
      targetId: transfer.sourceDocumentId,
      companyId: transfer.companyId,
      metadata: {
        reason: transfer.reason,
        sourcePath: transfer.sourcePath,
        archiveId: archiveRef.id,
        movedStorageCount: transfer.movedStorage.length,
        movedStorage: transfer.movedStorage,
      },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    pendingWrites += 3;
    archived += 1;
    if (pendingWrites >= BATCH_WRITE_LIMIT - 3) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
  }

  if (pendingWrites > 0) {
    await batch.commit();
  }

  return archived;
}

export async function queryOldDocsByTimestampFields(
  queryBase: FirebaseFirestore.Query<FirebaseFirestore.DocumentData>,
  timestampFields: string[],
  threshold: admin.firestore.Timestamp,
  sourceLabel: string,
): Promise<FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[]> {
  const byId = new Map<string, FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>>();

  for (const field of timestampFields) {
    try {
      const snapshot = await queryBase
        .where(field, '<', threshold)
        .limit(MAX_DOCS_PER_QUERY)
        .get();
      for (const doc of snapshot.docs) {
        byId.set(doc.id, doc);
      }
    } catch (error) {
      console.warn(`Skipping compliance query for ${sourceLabel}.${field}`, error);
    }
  }

  return Array.from(byId.values());
}
