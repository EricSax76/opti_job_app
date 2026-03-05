import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const requestConsent = functions.region("europe-west1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { candidateUid, poolId } = data;

  if (!candidateUid || !poolId) {
    throw new functions.https.HttpsError('invalid-argument', 'candidateUid and poolId are required.');
  }

  // In a real app, this would send an email or push notification to the candidate.
  // For this implementation, we log the request and potentially create a notification document.
  
  console.log(`Requesting consent from candidate ${candidateUid} for pool ${poolId}`);

  // Simulate sending a notification
  await admin.firestore().collection('notifications').add({
    userId: candidateUid,
    type: 'consent_request',
    poolId,
    message: 'A company wants to add you to their talent pool. Please provide your consent to retain your data.',
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
