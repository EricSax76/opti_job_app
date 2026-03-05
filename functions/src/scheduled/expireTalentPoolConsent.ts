import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const expireTalentPoolConsent = functions.region("europe-west1").pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const expiredMembersSnapshot = await db.collectionGroup('members')
      .where('consentGiven', '==', true)
      .where('consentExpiresAt', '<=', now)
      .get();

    if (expiredMembersSnapshot.empty) {
      console.log('No expired consents found.');
      return null;
    }

    const batch = db.batch();
    expiredMembersSnapshot.docs.forEach((doc) => {
      // Mark as expired or remove
      batch.update(doc.ref, {
        consentGiven: false,
        expiredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();
    console.log(`Processed ${expiredMembersSnapshot.size} expired consents.`);
    return null;
  });
