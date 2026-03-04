import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const matchCandidateWithSkills = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
  }

  const { applicationId, jobOfferId, quality = 'flash' } = data;

  if (!applicationId || !jobOfferId) {
    throw new functions.https.HttpsError('invalid-argument', 'applicationId and jobOfferId are required.');
  }

  // Fetch application, candidate and job offer data
  const appDoc = await admin.firestore().collection('applications').doc(applicationId).get();
  const offerDoc = await admin.firestore().collection('jobOffers').doc(jobOfferId).get();

  if (!appDoc.exists || !offerDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Application or Job Offer not found.');
  }

  // In a real implementation, we would call the Vertex AI / Gemini API here
  // based on the structured skills data in the documents.
  // For now, we simulate the logic and return a structured response compliant with AI Act.

  const aiResult = {
    score: 85,
    reasons: ['Strong alignment with React and TypeScript requirements.', 'Previous experience in similar roles.'],
    recommendations: ['Schedule technical interview.', 'Verify English proficiency.'],
    explanation: 'El candidato demuestra un alto nivel de competencia en las tecnologías core requeridas (React, TS) con más de 3 años de experiencia. Aunque le falta experiencia directa en Flutter, sus habilidades en React son altamente transferibles.',
    skillsOverlap: {
      matched: ['React', 'TypeScript', 'English'],
      missing: ['Flutter'],
      adjacent: ['React Native']
    },
    modelVersion: quality,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await appDoc.ref.update({ aiMatchResult: aiResult });

  return aiResult;
});
