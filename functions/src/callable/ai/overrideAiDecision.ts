import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const overrideAiDecision = functions.region("europe-west1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
  }

  const { applicationId, originalAiScore, reason } = data;

  if (!applicationId || originalAiScore === undefined || !reason) {
    throw new functions.https.HttpsError('invalid-argument', 'applicationId, originalAiScore and reason are required.');
  }

  const appRef = admin.firestore().collection('applications').doc(applicationId);

  await appRef.update({
    humanOverride: {
      overriddenBy: context.auth.uid,
      overriddenAt: admin.firestore.FieldValue.serverTimestamp(),
      originalAiScore: originalAiScore,
      reason: reason,
    }
  });

  return { success: true };
});
