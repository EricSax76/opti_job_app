import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const onApprovalUpdate = functions.region("europe-west1").firestore
  .document("approvals/{approvalId}")
  .onUpdate(async (change, context) => {
    const data = change.after.data();
    if (!data) return;

    // Prevent infinite loops by checking if the document is already processed
    // or if the status hasn't actually changed.
    const beforeData = change.before.data() || {};
    if (data.status !== "pending" && data.status === beforeData.status) {
      return; 
    }
    
    // Only process if it is currently pending
    if (data.status !== "pending") return;

    const approvers = data.approvers as any[];
    const allDecided = approvers.every((a) => a.status !== "pending");

    if (allDecided) {
      const anyRejected = approvers.some((a) => a.status === "rejected");
      const newStatus = anyRejected ? "rejected" : "approved";

      await change.after.ref.update({
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
