import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const submitEvaluation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const {
    applicationId,
    jobOfferId,
    companyId,
    criteria,
    overallScore,
    recommendation,
    comments,
    aiAssisted,
    aiOverridden,
    aiOriginalScore,
    aiExplanation,
  } = data;

  const db = admin.firestore();
  const evaluationRef = db.collection("evaluations").doc();
  const evaluationId = evaluationRef.id;

  const evaluation = {
    id: evaluationId,
    applicationId,
    jobOfferId,
    companyId,
    evaluatorUid: context.auth.uid,
    evaluatorName: context.auth.token.name || "Anonymous",
    criteria,
    overallScore,
    recommendation,
    comments,
    aiAssisted: aiAssisted || false,
    aiOverridden: aiOverridden || false,
    aiOriginalScore: aiOriginalScore || null,
    aiExplanation: aiExplanation || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await evaluationRef.set(evaluation);

  return { id: evaluationId };
});
