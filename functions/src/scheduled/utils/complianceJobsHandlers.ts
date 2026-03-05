import * as admin from 'firebase-admin';
import {
  JsonRecord,
  ArchiveTransferRecord,
  ArchiveTransferStats,
  VideoInterviewTtlStats,
  StorageMoveResult,
  THIRTY_DAYS_MS,
  CONSENT_RENEWAL_WINDOW_DAYS,
  BATCH_WRITE_LIMIT,
  MAX_DOCS_PER_QUERY,
  toTimestamp,
  asRecord,
  readCompanyId,
  readCandidateUid,
  isLegalHoldActive,
  extractStoragePath,
  moveStorageObjectToBlockedArchive,
  deleteStorageObjectIfExists,
  commitArchiveTransfers,
  queryOldDocsByTimestampFields,
} from './complianceJobsUtils';

export async function purgeExpiredApplications(
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

export async function purgeExpiredCurriculums(
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

export async function purgeExpiredCandidateVideos(
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

export async function prepareVideoInterviewRecordingsTtl(
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

export async function flagConsentsForRenewal(
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
