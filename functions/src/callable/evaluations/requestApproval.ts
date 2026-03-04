import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

type RecruiterRole = "admin" | "recruiter" | "hiring_manager" | "external_evaluator" | "viewer";

const APPROVAL_REQUESTER_ROLES: ReadonlySet<RecruiterRole> = new Set([
  "admin",
  "recruiter",
  "hiring_manager",
]);

function pickString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function normalizeApprovers(raw: unknown): Array<{ uid: string; name: string }> {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((entry) => {
      const map = entry as Record<string, unknown>;
      const uid = pickString(map?.uid);
      const name = pickString(map?.name);
      if (!uid || !name) return null;
      return { uid, name };
    })
    .filter((entry): entry is { uid: string; name: string } => entry !== null);
}

export const requestApproval = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const requesterUid = context.auth.uid;
  const applicationId = pickString(data?.applicationId);
  const jobOfferId = pickString(data?.jobOfferId);
  const type = pickString(data?.type);
  const approvers = normalizeApprovers(data?.approverUids);

  if (!applicationId || !jobOfferId || !type || approvers.length == 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "applicationId, jobOfferId, type and approverUids are required.",
    );
  }

  const db = admin.firestore();
  const applicationDoc = await db.collection("applications").doc(applicationId).get();
  if (!applicationDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Application not found.");
  }

  const application = applicationDoc.data() as Record<string, unknown>;
  const appJobOfferId = pickString(application.job_offer_id) || pickString(application.jobOfferId);
  if (appJobOfferId && appJobOfferId !== jobOfferId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "applicationId and jobOfferId mismatch.",
    );
  }

  const companyId = pickString(application.company_uid) || pickString(application.companyUid) || pickString(data?.companyId);
  if (!companyId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Application is missing company reference.",
    );
  }

  if (requesterUid !== companyId) {
    const recruiterDoc = await db.collection("recruiters").doc(requesterUid).get();
    if (!recruiterDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only company users or authorized recruiters can request approvals.",
      );
    }

    const recruiter = recruiterDoc.data() as Record<string, unknown>;
    const recruiterCompanyId = pickString(recruiter.companyId);
    const recruiterStatus = pickString(recruiter.status);
    const recruiterRole = pickString(recruiter.role) as RecruiterRole;

    if (
      recruiterCompanyId !== companyId ||
      recruiterStatus !== "active" ||
      !APPROVAL_REQUESTER_ROLES.has(recruiterRole)
    ) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Your role cannot request approvals for this company.",
      );
    }
  }

  const approvalRef = db.collection("approvals").doc();
  const approvalId = approvalRef.id;

  const approval = {
    id: approvalId,
    applicationId,
    jobOfferId,
    companyId,
    type,
    requestedBy: requesterUid,
    approvers: approvers.map((a) => ({
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
