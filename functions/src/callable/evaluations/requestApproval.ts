import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const requestApproval = functions.https.onCall(async (data, context) => {
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
    type,
    approverUids, // List of { uid, name }
  } = data;

  const db = admin.firestore();
  const approvalRef = db.collection("approvals").doc();
  const approvalId = approvalRef.id;

  const approval = {
    id: approvalId,
    applicationId,
    jobOfferId,
    companyId,
    type,
    requestedBy: context.auth.uid,
    approvers: approverUids.map((a: { uid: string; name: string }) => ({
      uid: a.uid,
      name: a.name,
      status: "pending",
      decidedAt: null,
      notes: null,
    })),
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await approvalRef.set(approval);

  return { id: approvalId };
});
