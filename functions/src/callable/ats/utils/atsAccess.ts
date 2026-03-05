import { HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { asTrimmedString } from "./salaryValidation";

/**
 * Resolves the company UID that the authenticated actor is allowed to act on behalf of.
 * Handles both company accounts and authorized recruiters.
 */
export async function resolveActorCompanyUid({
  actorUid,
  requestedCompanyUid,
}: {
  actorUid: string;
  requestedCompanyUid: string;
}): Promise<string> {
  const db = getFirestore();
  const actorCompanyDoc = await db.collection("companies").doc(actorUid).get();

  if (actorCompanyDoc.exists && !requestedCompanyUid) {
    return actorUid;
  }
  if (requestedCompanyUid && requestedCompanyUid === actorUid) {
    return actorUid;
  }

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Solo la empresa propietaria o un recruiter autorizado puede crear ofertas.",
    );
  }

  const recruiter = recruiterDoc.data() as Record<string, unknown>;
  const role = asTrimmedString(recruiter.role).toLowerCase();
  const status = asTrimmedString(recruiter.status).toLowerCase();
  const recruiterCompanyId = asTrimmedString(recruiter.companyId);

  if (!recruiterCompanyId || status !== "active") {
    throw new HttpsError(
      "permission-denied",
      "El recruiter no está activo o no tiene empresa asociada.",
    );
  }
  if (!["admin", "recruiter"].includes(role)) {
    throw new HttpsError(
      "permission-denied",
      "Tu rol de recruiter no tiene permisos para crear ofertas.",
    );
  }
  if (requestedCompanyUid && requestedCompanyUid !== recruiterCompanyId) {
    throw new HttpsError(
      "permission-denied",
      "No puedes crear ofertas para otra empresa.",
    );
  }
  return recruiterCompanyId;
}

/**
 * Asserts that the actor (company owner or active recruiter with valid role)
 * can manage (publish) an offer for the given companyId.
 */
export async function assertCanManageOffer(
  actorUid: string,
  companyId: string,
): Promise<void> {
  if (actorUid === companyId) return;

  const db = getFirestore();
  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Only company users or recruiters with publishing permissions can multipost.",
    );
  }
  const recruiter = recruiterDoc.data() as Record<string, unknown>;
  const recruiterCompanyId = String(recruiter.companyId ?? "").trim();
  const recruiterStatus = String(recruiter.status ?? "").trim();
  const recruiterRole = String(recruiter.role ?? "").trim();
  const canManageOffers = recruiterRole === "admin" || recruiterRole === "recruiter";
  if (recruiterCompanyId !== companyId || recruiterStatus !== "active" || !canManageOffers) {
    throw new HttpsError(
      "permission-denied",
      "Your role cannot publish this offer to external channels.",
    );
  }
}
