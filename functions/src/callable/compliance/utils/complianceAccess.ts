import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { asRecord, asTrimmedString } from "./complianceUtils";

export type AllowedManagerRole = "admin" | "recruiter";
export const MANAGER_ROLES = new Set(["admin", "recruiter", "hiring_manager"]);

export async function resolveCompanyAccess({
  actorUid,
  companyId,
}: {
  actorUid: string;
  companyId: string;
}): Promise<"company" | "recruiter"> {
  const db = admin.firestore();
  if (actorUid === companyId) return "company";

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Solo la empresa propietaria o reclutadores autorizados pueden procesar esta solicitud.",
    );
  }
  const recruiter = asRecord(recruiterDoc.data());
  const recruiterCompanyId = asTrimmedString(recruiter.companyId);
  const recruiterStatus = asTrimmedString(recruiter.status);
  const recruiterRole = asTrimmedString(recruiter.role);
  if (
    recruiterCompanyId !== companyId ||
    recruiterStatus !== "active" ||
    !MANAGER_ROLES.has(recruiterRole)
  ) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Tu rol no puede gestionar solicitudes ARSULIPO/AI Act para esta empresa.",
    );
  }
  return "recruiter";
}

export async function assertCompanyManagerAccess(
  db: FirebaseFirestore.Firestore,
  actorUid: string,
  companyId: string,
): Promise<"company" | AllowedManagerRole> {
  if (actorUid === companyId) return "company";

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only company managers can perform this action.",
    );
  }

  const recruiter = recruiterDoc.data() as Record<string, unknown>;
  const recruiterCompanyId = asTrimmedString(recruiter.companyId);
  const recruiterStatus = asTrimmedString(recruiter.status);
  const recruiterRole = asTrimmedString(recruiter.role);
  const allowedRoles: readonly AllowedManagerRole[] = ["admin", "recruiter"];

  if (
    recruiterCompanyId !== companyId ||
    recruiterStatus !== "active" ||
    !allowedRoles.includes(recruiterRole as AllowedManagerRole)
  ) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Your role cannot manage salary compliance for this company.",
    );
  }
  return recruiterRole as AllowedManagerRole;
}
