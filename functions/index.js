const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const region = 'europe-southwest1';
const regionalFunctions = functions.region(region);

exports.syncCompanyProfileToOffers = regionalFunctions.firestore
  .document('companies/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    const nameChanged = before.name !== after.name;
    const avatarChanged = before.avatar_url !== after.avatar_url;
    if (!nameChanged && !avatarChanged) {
      return null;
    }

    const uid = context.params.uid;
    const updates = {};
    if (nameChanged && after.name) {
      updates.company_name = after.name;
    }
    if (avatarChanged && after.avatar_url) {
      updates.company_avatar_url = after.avatar_url;
    }
    if (Object.keys(updates).length === 0) {
      return null;
    }

    const firestore = admin.firestore();
    const offersSnapshot = await firestore
      .collection('jobOffers')
      .where('company_uid', '==', uid)
      .get();

    if (offersSnapshot.empty) {
      return null;
    }

    const batch = firestore.batch();
    offersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, updates);
    });
    await batch.commit();
    return null;
  });

exports.syncCandidateProfileToApplications = regionalFunctions.firestore
  .document('candidates/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    const nameChanged = before.name !== after.name;
    const emailChanged = before.email !== after.email;
    const profileIdChanged = before.id !== after.id;
    if (!nameChanged && !emailChanged && !profileIdChanged) {
      return null;
    }

    const updates = {};
    if (nameChanged && after.name) {
      updates.candidateName = after.name;
    }
    if (emailChanged && after.email) {
      updates.candidateEmail = after.email;
    }
    if (profileIdChanged && Number.isInteger(after.id)) {
      updates.candidateProfileId = after.id;
    }
    if (Object.keys(updates).length === 0) {
      return null;
    }

    const uid = context.params.uid;
    const firestore = admin.firestore();
    const applicationsSnapshot = await firestore
      .collection('applications')
      .where('candidateId', '==', uid)
      .get();

    if (applicationsSnapshot.empty) {
      return null;
    }

    const batch = firestore.batch();
    applicationsSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, updates);
    });
    await batch.commit();
    return null;
  });

exports.syncJobOfferTitleToApplications = regionalFunctions.firestore
  .document('jobOffers/{offerDocId}')
  .onUpdate(async (change) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    const titleChanged = before.title !== after.title;
    if (!titleChanged || !after.title) {
      return null;
    }

    const jobOfferId = after.id;
    if (!Number.isInteger(jobOfferId)) {
      return null;
    }

    const firestore = admin.firestore();
    const applicationsSnapshot = await firestore
      .collection('applications')
      .where('jobOfferId', '==', jobOfferId)
      .get();

    if (applicationsSnapshot.empty) {
      return null;
    }

    const batch = firestore.batch();
    applicationsSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { jobOfferTitle: after.title });
    });
    await batch.commit();
    return null;
  });
