import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Submit a request to exercise ARSULIPO rights (GDPR).
 */
export const submitDataRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { type, description } = data;
  if (!type || !description) {
    throw new functions.https.HttpsError('invalid-argument', 'type and description are required.');
  }

  const now = admin.firestore.Timestamp.now();
  const dueAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + (30 * 24 * 60 * 60 * 1000));

  const request = {
    candidateUid: context.auth.uid,
    type,
    status: 'pending',
    description,
    createdAt: now,
    dueAt,
  };

  const docRef = await admin.firestore().collection('dataRequests').add(request);
  return { id: docRef.id };
});

/**
 * Process an ARSULIPO request by an admin or recruiter with high privilege.
 */
export const processDataRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { requestId, status, response } = data;
  if (!requestId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'requestId and status are required.');
  }

  await admin.firestore().collection('dataRequests').doc(requestId).update({
    status,
    response: response || null,
    processedBy: context.auth.uid,
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

/**
 * Export all candidate data for portability (JSON).
 */
export const exportCandidateData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const candidateUid = context.auth.uid;
  const db = admin.firestore();

  const [curriculum, apps, consents] = await Promise.all([
    db.collection('candidates').doc(candidateUid).collection('curriculum').get(),
    db.collection('applications').where('candidateId', '==', candidateUid).get(),
    db.collection('consentRecords').where('candidateUid', '==', candidateUid).get(),
  ]);

  const exportPackage = {
    candidateUid,
    exportedAt: new Date().toISOString(),
    curriculum: curriculum.docs.map(d => d.data()),
    applications: apps.docs.map(d => d.data()),
    consents: consents.docs.map(d => d.data()),
    legal_basis: 'RGPD Art. 20 (Portability Rights)',
  };

  return exportPackage;
});
