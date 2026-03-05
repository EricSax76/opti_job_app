import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

import {
  THREE_YEARS_MS,
  THIRTY_DAYS_MS,
  CONSENT_RENEWAL_WINDOW_DAYS,
} from './utils/complianceJobsUtils';

import {
  purgeExpiredApplications,
  purgeExpiredCurriculums,
  purgeExpiredCandidateVideos,
  prepareVideoInterviewRecordingsTtl,
  flagConsentsForRenewal,
} from './utils/complianceJobsHandlers';

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
