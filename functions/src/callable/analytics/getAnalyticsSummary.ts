import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Callable function to get a snapshot of current analytics for a company.
 */
export const getAnalyticsSummary = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { companyId, period } = data;
  if (!companyId || !period) {
    throw new functions.https.HttpsError('invalid-argument', 'companyId and period are required.');
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
        recruiterMetrics: {}
      }
    };
  }

  return analyticsDoc.data();
});
