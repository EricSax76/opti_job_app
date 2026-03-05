import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { asRecord, asTrimmedString, JsonRecord, SIGNABLE_STATUSES } from "./signatureUtils";

export async function resolveApplicationForCandidate({
  candidateUid,
  applicationId,
}: {
  candidateUid: string;
  applicationId: string;
}): Promise<{
  application: JsonRecord;
  companyUid: string;
  jobOfferId: string;
}> {
  const appDoc = await admin
    .firestore()
    .collection("applications")
    .doc(applicationId)
    .get();
  if (!appDoc.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "La candidatura indicada no existe.",
    );
  }

  const app = asRecord(appDoc.data());
  const ownerUid =
    asTrimmedString(app.candidate_uid) || asTrimmedString(app.candidateId);
  if (!ownerUid || ownerUid !== candidateUid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Solo puedes firmar ofertas sobre tus candidaturas.",
    );
  }

  const status = asTrimmedString(app.status).toLowerCase();
  if (!SIGNABLE_STATUSES.has(status)) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "La candidatura no está en estado firmable.",
    );
  }

  const companyUid =
    asTrimmedString(app.company_uid) || asTrimmedString(app.companyUid);
  const jobOfferId =
    asTrimmedString(app.job_offer_id) || asTrimmedString(app.jobOfferId);
  if (!companyUid || !jobOfferId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Faltan referencias de empresa u oferta para firmar.",
    );
  }

  return {
    application: app,
    companyUid,
    jobOfferId,
  };
}
