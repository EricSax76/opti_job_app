import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

type RecruiterRole =
  | "admin"
  | "recruiter"
  | "hiring_manager"
  | "external_evaluator"
  | "viewer";

const SCORE_ROLES: ReadonlySet<RecruiterRole> = new Set([
  "admin",
  "recruiter",
  "hiring_manager",
  "external_evaluator",
]);

function pickString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

export const submitEvaluation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const evaluatorUid = context.auth.uid;
  const applicationId = pickString(data?.applicationId);
  const jobOfferId = pickString(data?.jobOfferId);

  if (!applicationId || !jobOfferId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "applicationId and jobOfferId are required.",
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

  if (evaluatorUid !== companyId) {
    const recruiterDoc = await db.collection("recruiters").doc(evaluatorUid).get();
    if (!recruiterDoc.exists) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only company users or authorized recruiters can submit evaluations.",
      );
    }

    const recruiter = recruiterDoc.data() as Record<string, unknown>;
    const recruiterCompanyId = pickString(recruiter.companyId);
    const recruiterStatus = pickString(recruiter.status);
    const recruiterRole = pickString(recruiter.role) as RecruiterRole;

    if (
      recruiterCompanyId != companyId ||
      recruiterStatus !== "active" ||
      !SCORE_ROLES.has(recruiterRole)
    ) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Your role cannot submit evaluations for this company.",
      );
    }

    // External evaluators are constrained to explicitly assigned applications.
    if (recruiterRole === "external_evaluator") {
      const assignedTo = pickString(application.assignedTo);
      const assignedEvaluatorUid = pickString(application.assignedEvaluatorUid);
      const externalEvaluatorUids = Array.isArray(application.externalEvaluatorUids)
        ? (application.externalEvaluatorUids as unknown[]).map(pickString)
        : [];

      const isAssigned =
        assignedTo === evaluatorUid ||
        assignedEvaluatorUid === evaluatorUid ||
        externalEvaluatorUids.includes(evaluatorUid);

      if (!isAssigned) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "External evaluator is not assigned to this application.",
        );
      }
    }
  }

  const evaluationRef = db.collection("evaluations").doc();
  const evaluationId = evaluationRef.id;

  const evaluation = {
    id: evaluationId,
    applicationId,
    jobOfferId,
    companyId,
    evaluatorUid,
    evaluatorName: context.auth.token.name || "Anonymous",
    criteria: data?.criteria ?? [],
    overallScore: data?.overallScore ?? null,
    recommendation: data?.recommendation ?? null,
    comments: data?.comments ?? null,
    aiAssisted: data?.aiAssisted === true,
    aiOverridden: data?.aiOverridden === true,
    aiOriginalScore: data?.aiOriginalScore ?? null,
    aiExplanation: data?.aiExplanation ?? null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await evaluationRef.set(evaluation);

  return { id: evaluationId };
});
