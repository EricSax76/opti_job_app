import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Callable function to get a snapshot of current analytics for a company.
 */
export const getAnalyticsSummary = functions.region("europe-west1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { companyId, period } = data;
  if (!companyId || !period) {
    throw new functions.https.HttpsError('invalid-argument', 'companyId and period are required.');
  }

  const requesterUid = context.auth.uid;
  if (requesterUid !== String(companyId)) {
    const db = admin.firestore();
    const recruiterDoc = await db.collection('recruiters').doc(requesterUid).get();
    if (!recruiterDoc.exists) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only company users or authorized recruiters can access analytics.',
      );
    }

    const recruiter = recruiterDoc.data() as Record<string, unknown>;
    const recruiterCompanyId = String(recruiter.companyId ?? '').trim();
    const recruiterStatus = String(recruiter.status ?? '').trim();
    const recruiterRole = String(recruiter.role ?? '').trim();
    const canViewReports = ['admin', 'recruiter', 'viewer', 'hiring_manager'].includes(recruiterRole);

    if (recruiterCompanyId !== String(companyId) || recruiterStatus !== 'active' || !canViewReports) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Your recruiter role does not allow viewing analytics.',
      );
    }
  }

  const db = admin.firestore();
  const analyticsDoc = await db.collection('analytics')
    .doc(companyId)
    .collection('monthly')
    .doc(period)
    .get();

  if (!analyticsDoc.exists) {
    // Return empty metrics if not computed yet
    return {
      companyId,
      period,
      metrics: {
        offersPublished: 0,
        applicationsReceived: 0,
        applicationCompletionRate: 0,
        averageTimeToHire: 0,
        averageTimeToFill: 0,
        pipelineConversionRates: {},
        sourceEffectiveness: {},
        totalMultipostingSpendEur: 0,
        totalAttributedHireValueEur: 0,
        overallChannelRoi: 0,
        recruiterMetrics: {}
      }
    };
  }

  return analyticsDoc.data();
});
