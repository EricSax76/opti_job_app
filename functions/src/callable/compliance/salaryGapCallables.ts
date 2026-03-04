import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

type AllowedManagerRole = "admin" | "recruiter";

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function asOptionalNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeRoleKey(roleOrTitle: string): string {
  return roleOrTitle
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/\s+/g, "_")
    .slice(0, 80);
}

async function assertCompanyManagerAccess(
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

export const upsertSalaryBenchmark = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const companyId = asTrimmedString(data?.companyId);
    const roleOrTitle = asTrimmedString(data?.roleKey ?? data?.title);
    const maleAvg = asOptionalNumber(data?.maleAverageSalary);
    const femaleAvg = asOptionalNumber(data?.femaleAverageSalary);
    const nonBinaryAvg = asOptionalNumber(data?.nonBinaryAverageSalary);
    const sampleSize = Math.max(
      0,
      Math.trunc(asOptionalNumber(data?.sampleSize) ?? 0),
    );

    if (!companyId || !roleOrTitle) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "companyId y roleKey/title son obligatorios.",
      );
    }

    if (maleAvg == null && femaleAvg == null && nonBinaryAvg == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Debes enviar al menos una media salarial por género.",
      );
    }

    const db = admin.firestore();
    const actorUid = context.auth.uid;
    await assertCompanyManagerAccess(db, actorUid, companyId);

    const roleKey = normalizeRoleKey(roleOrTitle);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const payloads: Array<{ gender: string; averageSalary: number }> = [];
    if (maleAvg != null) payloads.push({ gender: "male", averageSalary: maleAvg });
    if (femaleAvg != null) payloads.push({ gender: "female", averageSalary: femaleAvg });
    if (nonBinaryAvg != null) payloads.push({ gender: "non_binary", averageSalary: nonBinaryAvg });

    const batch = db.batch();
    for (const row of payloads) {
      const id = `${companyId}_${roleKey}_${row.gender}`;
      const ref = db.collection("salaryBenchmarks").doc(id);
      batch.set(
        ref,
        {
          id,
          companyId,
          roleKey,
          roleLabel: roleOrTitle,
          gender: row.gender,
          averageSalary: row.averageSalary,
          sampleSize,
          source: "company_reported",
          updatedBy: actorUid,
          updatedAt: now,
        },
        { merge: true },
      );
    }
    await batch.commit();

    return {
      ok: true,
      companyId,
      roleKey,
      updatedRows: payloads.length,
    };
  });

export const submitSalaryGapJustification = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Debes iniciar sesión.");
    }

    const jobOfferId = asTrimmedString(data?.jobOfferId);
    const justification = asTrimmedString(data?.justification);
    const objectiveCriteria = Array.isArray(data?.objectiveCriteria)
      ? (data.objectiveCriteria as unknown[])
          .map(asTrimmedString)
          .filter((v) => v.length > 0)
      : [];

    if (!jobOfferId || !justification) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "jobOfferId y justification son obligatorios.",
      );
    }

    const db = admin.firestore();
    const offerRef = db.collection("jobOffers").doc(jobOfferId);
    const offerDoc = await offerRef.get();
    if (!offerDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Oferta no encontrada.");
    }

    const offer = offerDoc.data() as Record<string, unknown>;
    const companyId =
      asTrimmedString(offer.company_uid) ||
      asTrimmedString(offer.companyUid) ||
      asTrimmedString(offer.owner_uid);
    if (!companyId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "La oferta no tiene companyId asociado.",
      );
    }

    await assertCompanyManagerAccess(db, context.auth.uid, companyId);

    const currentStatus = asTrimmedString(offer.status);
    const requiresJustification =
      currentStatus === "blocked_pending_salary_justification" ||
      offer.salary_gap_justification_required === true;

    if (!requiresJustification) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Esta oferta no tiene un bloqueo activo por brecha salarial.",
      );
    }

    await offerRef.set(
      {
        status: "active",
        salary_gap_justification_required: false,
        salary_gap_justification_status: "submitted",
        salary_gap_justification: {
          text: justification,
          objectiveCriteria,
          submittedBy: context.auth.uid,
          submittedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        salary_gap_audit: {
          ...(offer.salary_gap_audit as Record<string, unknown> | undefined ?? {}),
          justificationSubmittedAt: admin.firestore.FieldValue.serverTimestamp(),
          justificationSubmittedBy: context.auth.uid,
        },
        publication_block_reason: admin.firestore.FieldValue.delete(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { ok: true, jobOfferId, status: "active" };
  });
