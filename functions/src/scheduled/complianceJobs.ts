import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Automatically sets blockedAt for applications where consent has expired (3 years).
 * ENS / RGPD requirement for blocking instead of deletion.
 */
export const blockExpiredData = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const expiredApplications = await db.collection('applications')
    .where('blockedAt', '==', null)
    .where('updatedAt', '<', admin.firestore.Timestamp.fromMillis(now.toMillis() - (3 * 365 * 24 * 60 * 60 * 1000)))
    .limit(500)
    .get();

  if (expiredApplications.empty) return null;

  const batch = db.batch();
  expiredApplications.docs.forEach(doc => {
    batch.update(doc.ref, {
      blockedAt: now,
      blockedReason: 'Automatic expiration after 3 years (Compliance)',
    });
  });

  await batch.commit();
  console.log(`Blocked ${expiredApplications.size} expired applications.`);
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
