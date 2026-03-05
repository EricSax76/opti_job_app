import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const addToPool = functions.region("europe-west1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { poolId, candidateUid, tags = [], source = 'manual', sourceApplicationId } = data;

  if (!poolId || !candidateUid) {
    throw new functions.https.HttpsError('invalid-argument', 'poolId and candidateUid are required.');
  }

  const db = admin.firestore();
  const poolRef = db.collection('talentPools').doc(poolId);
  const memberRef = poolRef.collection('members').doc(candidateUid);

  // Check if candidate exists and has given consent in the past (e.g., from another pool)
  // This is a simplified check.
  const existingMemberSnapshot = await db.collectionGroup('members')
    .where('candidateUid', '==', candidateUid)
    .where('consentGiven', '==', true)
    .where('consentExpiresAt', '>', admin.firestore.Timestamp.now())
    .limit(1)
    .get();

  const consentGiven = !existingMemberSnapshot.empty;
  const existingConsent = consentGiven ? existingMemberSnapshot.docs[0].data() : null;

  await db.runTransaction(async (transaction) => {
    const poolDoc = await transaction.get(poolRef);
    if (!poolDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Pool not found.');
    }

    transaction.set(memberRef, {
      candidateUid,
      addedBy: context.auth!.uid,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
      tags,
      source,
      sourceApplicationId,
      consentGiven: consentGiven,
      consentAt: existingConsent?.consentAt || null,
      consentExpiresAt: existingConsent?.consentExpiresAt || null,
    });

    transaction.update(poolRef, {
      memberCount: admin.firestore.FieldValue.increment(1),
    });
  });

  return { success: true, consentRequired: !consentGiven };
});
