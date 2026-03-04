import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

type JsonRecord = Record<string, unknown>;

const SIGNATURE_REQUEST_TTL_DAYS = 7;
const SIGNABLE_STATUSES = new Set(["offered", "accepted_pending_signature"]);

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

function sha256Hex(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function nowPlusDays(days: number): Date {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000);
}

async function logAuditEntry({
  action,
  actorUid,
  actorRole,
  targetType,
  targetId,
  companyId,
  metadata,
}: {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  companyId?: string | null;
  metadata: JsonRecord;
}): Promise<void> {
  await admin.firestore().collection("auditLogs").add({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: companyId ?? null,
    metadata,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function buildOfferDocumentHash({
  applicationId,
  candidateUid,
  companyUid,
  jobOfferId,
  offer,
}: {
  applicationId: string;
  candidateUid: string;
  companyUid: string;
  jobOfferId: string;
  offer: JsonRecord;
}): string {
  const canonicalPayload = {
    applicationId,
    candidateUid,
    companyUid,
    jobOfferId,
    title: asTrimmedString(offer.title),
    salaryMin: asTrimmedString(offer.salary_min ?? offer.salaryMin),
    salaryMax: asTrimmedString(offer.salary_max ?? offer.salaryMax),
    salaryCurrency: asTrimmedString(offer.salary_currency ?? offer.salaryCurrency),
    salaryPeriod: asTrimmedString(offer.salary_period ?? offer.salaryPeriod),
    contractType: asTrimmedString(offer.contract_type ?? offer.contractType),
    generatedAt: new Date().toISOString().slice(0, 10),
  };
  return sha256Hex(JSON.stringify(canonicalPayload));
}

async function resolveApplicationForCandidate({
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

/**
 * Candidate starts qualified signature flow for an offered application.
 */
export const startQualifiedOfferSignature = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    const candidateUid = context.auth.uid;
    const applicationId = asTrimmedString(data?.applicationId);
    const provider =
      asTrimmedString(data?.provider || "qualified_trust_service_eidas") ||
      "qualified_trust_service_eidas";
    if (!applicationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "applicationId es obligatorio.",
      );
    }

    const db = admin.firestore();
    const { companyUid, jobOfferId } = await resolveApplicationForCandidate({
      candidateUid,
      applicationId,
    });

    const offerDoc = await db.collection("jobOffers").doc(jobOfferId).get();
    if (!offerDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "La oferta asociada no existe.",
      );
    }
    const offer = asRecord(offerDoc.data());
    const documentHash = buildOfferDocumentHash({
      applicationId,
      candidateUid,
      companyUid,
      jobOfferId,
      offer,
    });

    const requestRef = db.collection("offerSignatureRequests").doc();
    const requestId = requestRef.id;
    const expiresAt = nowPlusDays(SIGNATURE_REQUEST_TTL_DAYS);
    const now = admin.firestore.FieldValue.serverTimestamp();

    await Promise.all([
      requestRef.set({
        id: requestId,
        applicationId,
        candidateUid,
        companyUid,
        jobOfferId,
        provider,
        legalFramework: "eIDAS_qualified_signature",
        documentHash,
        status: "pending_candidate_signature",
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        createdAt: now,
        updatedAt: now,
      }),
      db.collection("applications").doc(applicationId).set(
        {
          status: "accepted_pending_signature",
          contractSignature: {
            requestId,
            provider,
            legalFramework: "eIDAS_qualified_signature",
            status: "pending_candidate_signature",
            documentHash,
            startedAt: now,
            updatedAt: now,
          },
          updatedAt: now,
          updated_at: now,
        },
        { merge: true },
      ),
      db.collection("notifications").add({
        type: "qualified_signature_started",
        audience: "candidate",
        channel: "in_app",
        userUid: candidateUid,
        companyUid,
        applicationId,
        title: "Firma cualificada iniciada",
        message:
          "La oferta está lista para firma electrónica cualificada. Completa el proceso para validar la aceptación legal.",
        read: false,
        createdAt: now,
        updatedAt: now,
      }),
      logAuditEntry({
        action: "qualified_signature_started",
        actorUid: candidateUid,
        actorRole: "candidate",
        targetType: "offer_signature_request",
        targetId: requestId,
        companyId: companyUid,
        metadata: {
          applicationId,
          jobOfferId,
          provider,
          legalFramework: "eIDAS_qualified_signature",
        },
      }),
    ]);

    return {
      requestId,
      applicationId,
      provider,
      legalFramework: "eIDAS_qualified_signature",
      documentHash,
      expiresAt: expiresAt.toISOString(),
      signingChallengeHint:
        "Introduce OTP y huella del certificado cualificado para cerrar la firma.",
    };
  });

/**
 * Candidate confirms qualified signature using provider challenge data.
 */
export const confirmQualifiedOfferSignature = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    const candidateUid = context.auth.uid;
    const requestId = asTrimmedString(data?.requestId);
    const otpCode = asTrimmedString(data?.otpCode);
    const certificateFingerprint = asTrimmedString(data?.certificateFingerprint);
    const providerReference = asTrimmedString(data?.providerReference);
    if (!requestId || !otpCode || !certificateFingerprint || !providerReference) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "requestId, otpCode, certificateFingerprint y providerReference son obligatorios.",
      );
    }
    if (otpCode.length < 4 || otpCode.length > 10) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "OTP inválido para firma cualificada.",
      );
    }

    const db = admin.firestore();
    const requestRef = db.collection("offerSignatureRequests").doc(requestId);
    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Solicitud de firma no encontrada.",
      );
    }
    const request = asRecord(requestDoc.data());
    const ownerUid = asTrimmedString(request.candidateUid);
    if (!ownerUid || ownerUid !== candidateUid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "No puedes confirmar esta firma.",
      );
    }

    const requestStatus = asTrimmedString(request.status);
    if (requestStatus !== "pending_candidate_signature") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "La solicitud ya no está pendiente de firma.",
      );
    }

    const expiresAt = request.expiresAt as admin.firestore.Timestamp | undefined;
    if (expiresAt && expiresAt.toDate().getTime() < Date.now()) {
      throw new functions.https.HttpsError(
        "deadline-exceeded",
        "La solicitud de firma ha expirado.",
      );
    }

    const applicationId = asTrimmedString(request.applicationId);
    const companyUid = asTrimmedString(request.companyUid);
    const provider = asTrimmedString(request.provider);
    const documentHash = asTrimmedString(request.documentHash);
    const signatureSeal = sha256Hex(
      `${requestId}|${documentHash}|${certificateFingerprint}|${providerReference}|${otpCode}`,
    );

    const signatureRef = db.collection("qualifiedSignatures").doc();
    const signatureId = signatureRef.id;
    const now = admin.firestore.FieldValue.serverTimestamp();
    const signedAtIso = new Date().toISOString();

    await Promise.all([
      requestRef.set(
        {
          status: "signed",
          signedAt: now,
          signedAtIso,
          providerReference,
          certificateFingerprint,
          signatureSeal,
          updatedAt: now,
        },
        { merge: true },
      ),
      signatureRef.set({
        id: signatureId,
        requestId,
        applicationId,
        candidateUid,
        companyUid,
        provider,
        providerReference,
        legalFramework: "eIDAS_qualified_signature",
        documentHash,
        certificateFingerprint,
        signatureSeal,
        signedAt: now,
        signedAtIso,
        createdAt: now,
      }),
      db.collection("applications").doc(applicationId).set(
        {
          status: "accepted",
          contractSignature: {
            requestId,
            signatureId,
            provider,
            providerReference,
            legalFramework: "eIDAS_qualified_signature",
            status: "signed",
            documentHash,
            certificateFingerprint,
            signatureSeal,
            signedAt: now,
            signedAtIso,
            updatedAt: now,
            legalValidity:
              "qualified_electronic_signature_with_eidas_equivalence",
          },
          updatedAt: now,
          updated_at: now,
        },
        { merge: true },
      ),
      db.collection("notifications").add({
        type: "qualified_signature_completed",
        audience: "company",
        channel: "in_app",
        userUid: companyUid,
        companyUid,
        applicationId,
        title: "Oferta firmada cualificadamente",
        message:
          "La persona candidata completó la firma electrónica cualificada de la oferta.",
        read: false,
        createdAt: now,
        updatedAt: now,
      }),
      logAuditEntry({
        action: "qualified_signature_completed",
        actorUid: candidateUid,
        actorRole: "candidate",
        targetType: "qualified_signature",
        targetId: signatureId,
        companyId: companyUid,
        metadata: {
          requestId,
          applicationId,
          provider,
          providerReference,
          legalFramework: "eIDAS_qualified_signature",
        },
      }),
    ]);

    return {
      success: true,
      requestId,
      signatureId,
      applicationId,
      status: "accepted",
      signedAt: signedAtIso,
      legalValidity: "qualified_electronic_signature_with_eidas_equivalence",
    };
  });

/**
 * Candidate/company can consult current qualified signature status.
 */
export const getQualifiedOfferSignatureStatus = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    const requesterUid = context.auth.uid;
    const applicationId = asTrimmedString(data?.applicationId);
    if (!applicationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "applicationId es obligatorio.",
      );
    }

    const appDoc = await admin
      .firestore()
      .collection("applications")
      .doc(applicationId)
      .get();
    if (!appDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "La candidatura no existe.",
      );
    }
    const app = asRecord(appDoc.data());
    const candidateUid =
      asTrimmedString(app.candidate_uid) || asTrimmedString(app.candidateId);
    const companyUid =
      asTrimmedString(app.company_uid) || asTrimmedString(app.companyUid);
    if (requesterUid !== candidateUid && requesterUid !== companyUid) {
      const recruiterDoc = await admin
        .firestore()
        .collection("recruiters")
        .doc(requesterUid)
        .get();
      const recruiter = asRecord(recruiterDoc.data());
      const recruiterCompanyUid = asTrimmedString(recruiter.companyId);
      const recruiterStatus = asTrimmedString(recruiter.status);
      if (
        !recruiterDoc.exists ||
        recruiterCompanyUid !== companyUid ||
        recruiterStatus !== "active"
      ) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "No tienes acceso al estado de firma.",
        );
      }
    }

    const contractSignature = asRecord(
      app.contractSignature || app.contract_signature,
    );
    return {
      applicationId,
      status: asTrimmedString(app.status),
      contractSignature,
    };
  });
