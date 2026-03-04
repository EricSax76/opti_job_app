import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const onEvaluationCreate = functions.firestore
  .document("evaluations/{evaluationId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (!data) return;

    const { applicationId, overallScore } = data;
    const db = admin.firestore();

    const applicationRef = db.collection("applications").doc(applicationId);
    
    return db.runTransaction(async (transaction) => {
      const appDoc = await transaction.get(applicationRef);
      if (!appDoc.exists) return;

      const appData = appDoc.data() || {};
      const evalCount = (appData.evaluationCount || 0) + 1;
      const currentSum = (appData.evaluationScoreSum || 0) + overallScore;
      const averageScore = currentSum / evalCount;

      transaction.update(applicationRef, {
        evaluationCount: evalCount,
        evaluationScoreSum: currentSum,
        averageEvaluationScore: averageScore,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
  });
