import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { asRecord, asTrimmedString } from "./eudiUtils";

export async function resolveOrCreateAuthUser({
  email,
  fullName,
}: {
  email: string;
  fullName: string;
}): Promise<admin.auth.UserRecord> {
  const auth = admin.auth();
  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    const err = error as { code?: string };
    if (err.code !== "auth/user-not-found") {
      throw error;
    }
  }

  return auth.createUser({
    email,
    displayName: fullName || undefined,
    emailVerified: true,
  });
}

export async function resolveCompanyUidFromApplication({
  candidateUid,
  applicationId,
}: {
  candidateUid: string;
  applicationId: string;
}): Promise<{ companyUid: string; jobOfferId: string }> {
  const db = admin.firestore();
  const appDoc = await db.collection("applications").doc(applicationId).get();
  if (!appDoc.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "La candidatura indicada no existe.",
    );
  }
  const app = asRecord(appDoc.data());
  const appCandidateUid =
    asTrimmedString(app.candidate_uid) || asTrimmedString(app.candidateId);
  if (!appCandidateUid || appCandidateUid !== candidateUid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Solo puedes compartir pruebas sobre tus candidaturas.",
    );
  }
  const companyUid =
    asTrimmedString(app.company_uid) || asTrimmedString(app.companyUid);
  const jobOfferId =
    asTrimmedString(app.job_offer_id) || asTrimmedString(app.jobOfferId);

  if (!companyUid) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "No se pudo resolver la empresa destinataria de la prueba.",
    );
  }
  return { companyUid, jobOfferId };
}

export async function assertCompanyOrRecruiterAccess({
  actorUid,
  companyUid,
}: {
  actorUid: string;
  companyUid: string;
}): Promise<"company" | "recruiter"> {
  if (actorUid === companyUid) return "company";

  const recruiterDoc = await admin
    .firestore()
    .collection("recruiters")
    .doc(actorUid)
    .get();
  if (!recruiterDoc.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "No tienes acceso a esta prueba.",
    );
  }
  const recruiter = asRecord(recruiterDoc.data());
  const recruiterCompany = asTrimmedString(recruiter.companyId);
  const recruiterStatus = asTrimmedString(recruiter.status);
  if (recruiterCompany !== companyUid || recruiterStatus !== "active") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "No tienes acceso a esta prueba.",
    );
  }
  return "recruiter";
}
