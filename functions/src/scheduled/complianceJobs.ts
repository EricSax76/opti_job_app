import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const THREE_YEARS_MS = 3 * 365 * 24 * 60 * 60 * 1000;
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
const CONSENT_RENEWAL_WINDOW_DAYS = 30;
const MAX_DOCS_PER_QUERY = 250;
const BATCH_WRITE_LIMIT = 450;
const BLOCKED_ARCHIVE_RETENTION_DAYS = 3 * 365;

type JsonRecord = Record<string, unknown>;

interface StorageMoveResult {
  sourcePath: string;
  archivePath: string;
}

interface ArchiveTransferRecord {
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

interface ArchiveTransferStats {
  archivedCount: number;
  skippedLegalHoldCount: number;
}

interface VideoInterviewTtlStats {
  ttlAssignedCount: number;
  expiredStillPresentCount: number;
  skippedLegalHoldCount: number;
  scannedCount: number;
}

function toTimestamp(value: unknown): admin.firestore.Timestamp | null {
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

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return '';
  return String(value).trim();
}

function asRecord(value: unknown): JsonRecord | null {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'object' || Array.isArray(value)) return null;
  return value as JsonRecord;
}

function toNullableString(value: unknown): string | null {
  const normalized = asTrimmedString(value);
  return normalized.length > 0 ? normalized : null;
}

function readCompanyId(data: JsonRecord): string | null {
  return toNullableString(data.company_uid ?? data.companyUid ?? data.companyId ?? data.owner_uid);
}

function readCandidateUid(data: JsonRecord): string | null {
  return toNullableString(data.candidate_uid ?? data.candidateUid ?? data.uid);
}

function archiveBlockedUntil(now: admin.firestore.Timestamp): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromMillis(
    now.toMillis() + (BLOCKED_ARCHIVE_RETENTION_DAYS * 24 * 60 * 60 * 1000),
  );
}

function isLegalHoldActive(value: unknown): boolean {
  if (value === true) return true;
  if (value === false || value == null) return false;
  const legalHold = asRecord(value);
  if (legalHold == null) return false;
  if (legalHold.active === true) return true;
  const status = asTrimmedString(legalHold.status).toLowerCase();
  return ['active', 'on', 'enabled', 'legal_hold'].includes(status);
}

function extractStoragePath(raw: unknown): string | null {
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

async function moveStorageObjectToBlockedArchive(
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

async function deleteStorageObjectIfExists(path: string): Promise<void> {
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

async function commitArchiveTransfers(
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

async function queryOldDocsByTimestampFields(
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

  return [...byId.values()];
}

async function purgeExpiredApplications(
  threshold: admin.firestore.Timestamp,
  now: admin.firestore.Timestamp,
): Promise<ArchiveTransferStats> {
  const db = admin.firestore();
  const oldDocs = await queryOldDocsByTimestampFields(
    db.collection('applications'),
    ['updated_at', 'updatedAt', 'submitted_at', 'submittedAt'],
    threshold,
    'applications',
  );

  if (oldDocs.length === 0) {
    return { archivedCount: 0, skippedLegalHoldCount: 0 };
  }

  const transfers: ArchiveTransferRecord[] = [];
  let skippedLegalHoldCount = 0;

  for (const doc of oldDocs) {
    const data = doc.data() as JsonRecord;
    if (isLegalHoldActive(data.legalHold)) {
      skippedLegalHoldCount += 1;
      continue;
    }

    const status = String(data.status ?? '').toLowerCase();
    if (status === 'hired') {
      continue;
    }

    const rawAdditionalDocuments = data.additional_documents ?? data.additionalDocuments;
    const additionalDocuments = Array.isArray(rawAdditionalDocuments)
      ? rawAdditionalDocuments
      : [];

    const movedStorage: StorageMoveResult[] = [];
    for (const rawPath of additionalDocuments) {
      const path = extractStoragePath(rawPath);
      if (path == null) continue;
      const moved = await moveStorageObjectToBlockedArchive(
        path,
        `applications/${doc.id}`,
      );
      if (moved != null) {
        movedStorage.push(moved);
      }
    }

    transfers.push({
      sourceRef: doc.ref,
      sourceCollection: 'applications',
      sourceDocumentId: doc.id,
      sourcePath: doc.ref.path,
      companyId: readCompanyId(data),
      candidateUid: readCandidateUid(data),
      payload: data,
      reason: 'retention_expired_3y_application',
      movedStorage,
    });
  }

  const archivedCount = await commitArchiveTransfers(transfers, now);
  return { archivedCount, skippedLegalHoldCount };
}

async function purgeExpiredCurriculums(
  threshold: admin.firestore.Timestamp,
  now: admin.firestore.Timestamp,
): Promise<ArchiveTransferStats> {
  const db = admin.firestore();
  const oldDocs = await queryOldDocsByTimestampFields(
    db.collectionGroup('curriculum'),
    ['updated_at', 'updatedAt'],
    threshold,
    'collectionGroup(curriculum)',
  );

  if (oldDocs.length === 0) {
    return { archivedCount: 0, skippedLegalHoldCount: 0 };
  }

  const transfers: ArchiveTransferRecord[] = [];
  let skippedLegalHoldCount = 0;

  for (const doc of oldDocs) {
    // El CV principal vive en candidates/{uid}/curriculum/main
    const pathSegments = doc.ref.path.split('/');
    if (
      pathSegments.length < 4 ||
      pathSegments[0] !== 'candidates' ||
      pathSegments[2] !== 'curriculum'
    ) {
      continue;
    }
    const data = doc.data() as JsonRecord;
    if (isLegalHoldActive(data.legalHold)) {
      skippedLegalHoldCount += 1;
      continue;
    }

    const movedStorage: StorageMoveResult[] = [];
    const attachment = asRecord(data.attachment);
    const storagePath = extractStoragePath(
      attachment?.storage_path ?? attachment?.storagePath,
    );
    if (storagePath != null) {
      const moved = await moveStorageObjectToBlockedArchive(
        storagePath,
        `curriculum/${doc.id}`,
      );
      if (moved != null) {
        movedStorage.push(moved);
      }
    }

    const candidateUid = pathSegments.length >= 2 ? pathSegments[1] : null;
    transfers.push({
      sourceRef: doc.ref,
      sourceCollection: 'curriculum',
      sourceDocumentId: doc.id,
      sourcePath: doc.ref.path,
      companyId: readCompanyId(data),
      candidateUid,
      payload: data,
      reason: 'retention_expired_3y_curriculum',
      movedStorage,
    });
  }

  const archivedCount = await commitArchiveTransfers(transfers, now);
  return { archivedCount, skippedLegalHoldCount };
}

async function purgeExpiredCandidateVideos(
  threshold: admin.firestore.Timestamp,
): Promise<number> {
  const db = admin.firestore();
  const oldDocs = await queryOldDocsByTimestampFields(
    db.collection('candidates'),
    ['video_curriculum.updated_at', 'video_curriculum.updatedAt'],
    threshold,
    'candidates',
  );

  if (oldDocs.length === 0) return 0;

  let batch = db.batch();
  let pending = 0;
  let purgedVideos = 0;

  for (const doc of oldDocs) {
    const data = doc.data() as JsonRecord;
    if (isLegalHoldActive(data.legalHold)) {
      continue;
    }
    const videoData = data.video_curriculum;
    if (videoData == null || typeof videoData !== 'object') {
      continue;
    }
    if (isLegalHoldActive((videoData as JsonRecord).legalHold)) {
      continue;
    }

    const videoUpdatedAt = toTimestamp(
      (videoData as Record<string, unknown>)['updated_at'] ??
      (videoData as Record<string, unknown>)['updatedAt'],
    );
    if (videoUpdatedAt == null || videoUpdatedAt.toMillis() >= threshold.toMillis()) {
      continue;
    }

    const path = extractStoragePath(
      (videoData as Record<string, unknown>)['storage_path'] ??
      (videoData as Record<string, unknown>)['storagePath'],
    );
    if (path != null) {
      await deleteStorageObjectIfExists(path);
    }

    batch.update(doc.ref, {
      video_curriculum: admin.firestore.FieldValue.delete(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    pending += 1;
    purgedVideos += 1;

    if (pending >= BATCH_WRITE_LIMIT) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }

  if (pending > 0) {
    await batch.commit();
  }

  return purgedVideos;
}

async function prepareVideoInterviewRecordingsTtl(
  now: admin.firestore.Timestamp,
): Promise<VideoInterviewTtlStats> {
  const db = admin.firestore();
  let snapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>;
  try {
    snapshot = await db
      .collection('videoInterviewRecordings')
      .orderBy('createdAt', 'desc')
      .limit(MAX_DOCS_PER_QUERY)
      .get();
  } catch (_) {
    snapshot = await db
      .collection('videoInterviewRecordings')
      .limit(MAX_DOCS_PER_QUERY)
      .get();
  }

  if (snapshot.empty) {
    return {
      ttlAssignedCount: 0,
      expiredStillPresentCount: 0,
      skippedLegalHoldCount: 0,
      scannedCount: 0,
    };
  }

  let batch = db.batch();
  let pending = 0;
  let ttlAssignedCount = 0;
  let expiredStillPresentCount = 0;
  let skippedLegalHoldCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data() as JsonRecord;
    if (isLegalHoldActive(data.legalHold)) {
      skippedLegalHoldCount += 1;
      continue;
    }

    const ttlDeleteAt = toTimestamp(data.ttlDeleteAt);
    if (ttlDeleteAt != null && ttlDeleteAt.toMillis() <= now.toMillis()) {
      expiredStillPresentCount += 1;
    }

    if (ttlDeleteAt != null) {
      continue;
    }

    const baseTimestamp = toTimestamp(
      data.recordedAt ?? data.createdAt ?? data.uploadedAt,
    );
    if (baseTimestamp == null) {
      continue;
    }

    const computedTtlDeleteAt = admin.firestore.Timestamp.fromMillis(
      baseTimestamp.toMillis() + THIRTY_DAYS_MS,
    );
    batch.set(doc.ref, {
      ttlDeleteAt: computedTtlDeleteAt,
      ttlPolicy: {
        version: 'videoInterviewRecordings.v1',
        retentionDays: 30,
        assignedAt: now,
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    pending += 1;
    ttlAssignedCount += 1;

    if (pending >= BATCH_WRITE_LIMIT) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }

  if (pending > 0) {
    await batch.commit();
  }

  return {
    ttlAssignedCount,
    expiredStillPresentCount,
    skippedLegalHoldCount,
    scannedCount: snapshot.size,
  };
}

async function flagConsentsForRenewal(
  now: admin.firestore.Timestamp,
): Promise<number> {
  const db = admin.firestore();
  const renewalThreshold = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + (CONSENT_RENEWAL_WINDOW_DAYS * 24 * 60 * 60 * 1000),
  );

  const expiringConsents = await db.collection('consentRecords')
    .where('expiresAt', '>=', now)
    .where('expiresAt', '<=', renewalThreshold)
    .limit(MAX_DOCS_PER_QUERY)
    .get();

  if (expiringConsents.empty) return 0;

  let batch = db.batch();
  let pending = 0;
  let flagged = 0;

  for (const doc of expiringConsents.docs) {
    const data = doc.data() as Record<string, unknown>;
    const granted = data.granted == true;
    const revokedAt = data.revokedAt;
    const renewalRequestedAt = data.renewalRequestedAt;

    if (!granted || revokedAt != null || renewalRequestedAt != null) {
      continue;
    }

    batch.update(doc.ref, {
      renewalRequestedAt: now,
      renewalStatus: 'pending',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    pending += 1;
    flagged += 1;

    if (pending >= BATCH_WRITE_LIMIT) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }

  if (pending > 0) {
    await batch.commit();
  }

  return flagged;
}

/**
 * Purga automática de datos expirados (AEPD):
 * - Aplicaciones/CVs no contratados con más de 3 años.
 * - Vídeos con más de 30 días.
 * - Marcado de consentimientos próximos a expirar para renovación.
 */
export const blockExpiredData = functions.region("europe-west1").pubsub.schedule('every 24 hours').onRun(async (context) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const threeYearThreshold = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - THREE_YEARS_MS,
  );
  const videoThreshold = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - THIRTY_DAYS_MS,
  );

  const [applicationsArchiveStats, curriculumsArchiveStats, purgedVideos, flaggedConsents, videoInterviewTtlStats] =
    await Promise.all([
      purgeExpiredApplications(threeYearThreshold, now),
      purgeExpiredCurriculums(threeYearThreshold, now),
      purgeExpiredCandidateVideos(videoThreshold),
      flagConsentsForRenewal(now),
      prepareVideoInterviewRecordingsTtl(now),
    ]);

  const blockedArchiveMoves = applicationsArchiveStats.archivedCount +
    curriculumsArchiveStats.archivedCount;
  const legalHoldSkips = applicationsArchiveStats.skippedLegalHoldCount +
    curriculumsArchiveStats.skippedLegalHoldCount;

  const reportDate = now.toDate().toISOString().slice(0, 10);
  await db.collection('complianceDailyReports').doc(reportDate).set(
    {
      reportDate,
      generatedAt: now,
      applicationsPurged: 0,
      curriculumsPurged: 0,
      applicationsArchivedBlocked: applicationsArchiveStats.archivedCount,
      curriculumsArchivedBlocked: curriculumsArchiveStats.archivedCount,
      blockedArchiveMoves,
      legalHoldSkips,
      candidateVideosPurged: purgedVideos,
      consentsFlaggedForRenewal: flaggedConsents,
      retention: {
        applicationsPurged: 0,
        curriculumsPurged: 0,
        applicationsArchivedBlocked: applicationsArchiveStats.archivedCount,
        curriculumsArchivedBlocked: curriculumsArchiveStats.archivedCount,
        blockedArchiveMoves,
        legalHoldSkips,
        candidateVideosPurged: purgedVideos,
      },
      videoInterviewTtl: {
        collection: 'videoInterviewRecordings',
        ttlField: 'ttlDeleteAt',
        retentionDays: 30,
        ttlAssignedCount: videoInterviewTtlStats.ttlAssignedCount,
        expiredStillPresentCount: videoInterviewTtlStats.expiredStillPresentCount,
        skippedLegalHoldCount: videoInterviewTtlStats.skippedLegalHoldCount,
        scannedCount: videoInterviewTtlStats.scannedCount,
      },
      consent: {
        consentsFlaggedForRenewal: flaggedConsents,
      },
      thresholds: {
        applicationsAndCurriculumDays: Math.trunc(THREE_YEARS_MS / (24 * 60 * 60 * 1000)),
        videosDays: Math.trunc(THIRTY_DAYS_MS / (24 * 60 * 60 * 1000)),
        consentRenewalWindowDays: CONSENT_RENEWAL_WINDOW_DAYS,
      },
      source: 'scheduled_blockExpiredData',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(
    [
      `Compliance daily job completed.`,
      `applicationsArchived=${applicationsArchiveStats.archivedCount}`,
      `curriculumsArchived=${curriculumsArchiveStats.archivedCount}`,
      `archiveMoves=${blockedArchiveMoves}`,
      `legalHoldSkips=${legalHoldSkips}`,
      `videos=${purgedVideos}`,
      `ttlAssigned=${videoInterviewTtlStats.ttlAssignedCount}`,
      `ttlExpiredStillPresent=${videoInterviewTtlStats.expiredStillPresentCount}`,
      `consentsFlagged=${flaggedConsents}`,
    ].join(' '),
  );
  return null;
});

/**
 * Periodically archives audit logs older than 1 year.
 */
export const auditLogCleanup = functions
  .region("europe-west1")
  .pubsub
  .schedule("0 2 1 * *")
  .timeZone("Europe/Madrid")
  .onRun(async () => {
  const db = admin.firestore();
  const threshold = admin.firestore.Timestamp.fromMillis(Date.now() - (365 * 24 * 60 * 60 * 1000));

  const oldLogs = await db.collection('auditLogs')
    .where('timestamp', '<', threshold)
    .limit(1000)
    .get();

  if (oldLogs.empty) return null;

  const batch = db.batch();
  oldLogs.docs.forEach(doc => {
    // In a real production environment, here you would move doc.data() to Google Cloud Storage
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Archived ${oldLogs.size} old audit logs.`);
  return null;
});
