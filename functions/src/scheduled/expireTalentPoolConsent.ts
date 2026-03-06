import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const expireTalentPoolConsent = functions.region("europe-west1").pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    let expiredMembersSnapshot = await db.collectionGroup('members')
      .where('consentGiven', '==', true)
      .where('consentExpiresAt', '<=', now)
      .limit(500)
      .get();

    if (expiredMembersSnapshot.empty) {
      console.log('No expired consents found.');
      return null;
    }

    let totalProcessed = 0;
    while (!expiredMembersSnapshot.empty) {
      const batch = db.batch();
      expiredMembersSnapshot.docs.forEach((doc) => {
        // Mark as expired or remove
        batch.update(doc.ref, {
          consentGiven: false,
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      totalProcessed += expiredMembersSnapshot.size;

      // Fetch next batch
      expiredMembersSnapshot = await db.collectionGroup('members')
        .where('consentGiven', '==', true)
        .where('consentExpiresAt', '<=', now)
        .limit(500)
        .get();
    }

    console.log(`Processed ${totalProcessed} expired consents.`);
    return null;
  });
