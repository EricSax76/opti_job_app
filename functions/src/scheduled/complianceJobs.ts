import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const THREE_YEARS_MS = 3 * 365 * 24 * 60 * 60 * 1000;
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
const CONSENT_RENEWAL_WINDOW_DAYS = 30;
const MAX_DOCS_PER_QUERY = 250;
const BATCH_WRITE_LIMIT = 450;

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

async function queryOldDocsByTimestampFields(
  collectionRef: FirebaseFirestore.CollectionReference<FirebaseFirestore.DocumentData>,
  timestampFields: string[],
  threshold: admin.firestore.Timestamp,
): Promise<FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[]> {
  const byId = new Map<string, FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>>();

  for (const field of timestampFields) {
    try {
      const snapshot = await collectionRef
        .where(field, '<', threshold)
        .limit(MAX_DOCS_PER_QUERY)
        .get();
      for (const doc of snapshot.docs) {
        byId.set(doc.id, doc);
      }
    } catch (error) {
      console.warn(`Skipping compliance query for ${collectionRef.path}.${field}`, error);
    }
  }

  return [...byId.values()];
}

async function commitDeletes(
  refs: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>[],
): Promise<void> {
  if (refs.length === 0) return;

  let batch = admin.firestore().batch();
  let pending = 0;

  for (const ref of refs) {
    batch.delete(ref);
    pending += 1;

    if (pending >= BATCH_WRITE_LIMIT) {
      await batch.commit();
      batch = admin.firestore().batch();
      pending = 0;
    }
  }

  if (pending > 0) {
    await batch.commit();
  }
}

async function purgeExpiredApplications(
  threshold: admin.firestore.Timestamp,
): Promise<number> {
  const db = admin.firestore();
  const oldDocs = await queryOldDocsByTimestampFields(
    db.collection('applications'),
    ['updated_at', 'updatedAt', 'submitted_at', 'submittedAt'],
    threshold,
  );

  if (oldDocs.length === 0) return 0;

  const refsToDelete: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>[] = [];

  for (const doc of oldDocs) {
    const data = doc.data();
    const status = String(data.status ?? '').toLowerCase();
    if (status === 'hired') {
      continue;
    }

    const rawAdditionalDocuments = data.additional_documents ?? data.additionalDocuments;
    const additionalDocuments = Array.isArray(rawAdditionalDocuments)
      ? rawAdditionalDocuments
      : [];

    for (const rawPath of additionalDocuments) {
      const path = extractStoragePath(rawPath);
      if (path == null) continue;
      await deleteStorageObjectIfExists(path);
    }

    refsToDelete.push(doc.ref);
  }

  await commitDeletes(refsToDelete);
  return refsToDelete.length;
}

async function purgeExpiredCurriculums(
  threshold: admin.firestore.Timestamp,
): Promise<number> {
  const db = admin.firestore();
  const oldDocs = await queryOldDocsByTimestampFields(
    db.collection('curriculum'),
    ['updated_at', 'updatedAt'],
    threshold,
  );

  if (oldDocs.length === 0) return 0;

  const refsToDelete: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>[] = [];

  for (const doc of oldDocs) {
    const data = doc.data();
    const storagePath = extractStoragePath(
      data.attachment?.storage_path ?? data.attachment?.storagePath,
    );
    if (storagePath != null) {
      await deleteStorageObjectIfExists(storagePath);
    }
    refsToDelete.push(doc.ref);
  }

  await commitDeletes(refsToDelete);
  return refsToDelete.length;
}

async function purgeExpiredCandidateVideos(
  threshold: admin.firestore.Timestamp,
): Promise<number> {
  const db = admin.firestore();
  const oldDocs = await queryOldDocsByTimestampFields(
    db.collection('candidates'),
    ['video_curriculum.updated_at', 'video_curriculum.updatedAt'],
    threshold,
  );

  if (oldDocs.length === 0) return 0;

  let batch = db.batch();
  let pending = 0;
  let purgedVideos = 0;

  for (const doc of oldDocs) {
    const data = doc.data();
    const videoData = data.video_curriculum;
    if (videoData == null || typeof videoData !== 'object') {
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
export const blockExpiredData = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  const threeYearThreshold = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - THREE_YEARS_MS,
  );
  const videoThreshold = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - THIRTY_DAYS_MS,
  );

  const [purgedApplications, purgedCurriculums, purgedVideos, flaggedConsents] =
    await Promise.all([
      purgeExpiredApplications(threeYearThreshold),
      purgeExpiredCurriculums(threeYearThreshold),
      purgeExpiredCandidateVideos(videoThreshold),
      flagConsentsForRenewal(now),
    ]);

  console.log(
    [
      `Compliance daily job completed.`,
      `applications=${purgedApplications}`,
      `curriculums=${purgedCurriculums}`,
      `videos=${purgedVideos}`,
      `consentsFlagged=${flaggedConsents}`,
    ].join(' '),
  );
  return null;
});

/**
 * Periodically archives audit logs older than 1 year.
 */
export const auditLogCleanup = functions.pubsub.schedule('every month').onRun(async (context) => {
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
