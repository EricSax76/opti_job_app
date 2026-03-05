import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

type JsonRecord = Record<string, unknown>;

const DEFAULT_PROOF_SCHEMA_VERSION = "2026.1";

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

function randomHex(bytes = 24): string {
  return crypto.randomBytes(bytes).toString("hex");
}

function nowPlusMinutes(minutes: number): Date {
  return new Date(Date.now() + minutes * 60 * 1000);
}

function resolveCredentialTrace(
  credential: JsonRecord,
): {
  verificationMethod: string | null;
  issuerDid: string | null;
  credentialType: string | null;
  proofSchemaVersion: string;
} {
  const metadata = asRecord(credential.metadata);
  const verificationMethod =
    asTrimmedString(credential.verificationMethod) ||
    asTrimmedString(metadata.verificationMethod) ||
    null;
  const issuerDid =
    asTrimmedString(credential.issuerDid) ||
    asTrimmedString(metadata.issuerDid) ||
    asTrimmedString(credential.issuer) ||
    null;
  const credentialType =
    asTrimmedString(credential.credentialType) ||
    asTrimmedString(metadata.credentialType) ||
    asTrimmedString(credential.type) ||
    null;
  const proofSchemaVersion =
    asTrimmedString(credential.proofSchemaVersion) ||
    asTrimmedString(metadata.proofSchemaVersion) ||
    DEFAULT_PROOF_SCHEMA_VERSION;

  return {
    verificationMethod,
    issuerDid,
    credentialType,
    proofSchemaVersion,
  };
}

async function logAuditEntry({
  action,
  actorUid,
  actorRole,
  targetType,
  targetId,
  companyId,
  metadata,
  verificationMethod,
  issuerDid,
  credentialType,
  proofSchemaVersion,
}: {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  companyId?: string | null;
  metadata: JsonRecord;
  verificationMethod?: string | null;
  issuerDid?: string | null;
  credentialType?: string | null;
  proofSchemaVersion?: string | null;
}): Promise<void> {
  await admin.firestore().collection("auditLogs").add({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: companyId ?? null,
    verificationMethod: verificationMethod ?? null,
    issuerDid: issuerDid ?? null,
    credentialType: credentialType ?? null,
    proofSchemaVersion: proofSchemaVersion ?? null,
    metadata,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function resolveCompanyUidFromApplication({
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

async function assertCompanyOrRecruiterAccess({
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

/**
 * Candidate creates a selective disclosure proof (ZKP-style) for a verified credential.
 * Returns proofId + proofToken without exposing full credential document.
 */
export const createSelectiveDisclosureProof = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    const candidateUid = context.auth.uid;
    const credentialId = asTrimmedString(data?.credentialId);
    const claimKey = asTrimmedString(data?.claimKey || "type") || "type";
    const statement = asTrimmedString(data?.statement);
    const applicationId = asTrimmedString(data?.applicationId);
    const audienceCompanyUid = asTrimmedString(data?.audienceCompanyUid);
    const expiresInMinutesInput = Number(data?.expiresInMinutes ?? 60);
    const expiresInMinutes = Number.isFinite(expiresInMinutesInput)
      ? Math.min(24 * 60, Math.max(5, Math.round(expiresInMinutesInput)))
      : 60;

    if (!credentialId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "credentialId es obligatorio.",
      );
    }

    const db = admin.firestore();
    const credentialDoc = await db
      .collection("candidates")
      .doc(candidateUid)
      .collection("verifiedCredentials")
      .doc(credentialId)
      .get();
    if (!credentialDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "No existe la credencial verificada indicada.",
      );
    }
    const credential = asRecord(credentialDoc.data());
    const metadata = asRecord(credential.metadata);
    const trace = resolveCredentialTrace(credential);

    const claimValue =
      asTrimmedString(credential[claimKey]) ||
      asTrimmedString(metadata[claimKey]) ||
      asTrimmedString(credential.type) ||
      "present";

    let companyUid = audienceCompanyUid;
    let jobOfferId = "";
    if (applicationId) {
      const applicationContext = await resolveCompanyUidFromApplication({
        candidateUid,
        applicationId,
      });
      companyUid = companyUid || applicationContext.companyUid;
      jobOfferId = applicationContext.jobOfferId;
    }
    if (!companyUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Debes indicar audienceCompanyUid o applicationId.",
      );
    }

    const nonce = randomHex(16);
    const proofDigest = sha256Hex(
      `${candidateUid}|${credentialId}|${claimKey}|${claimValue}|${nonce}`,
    );
    const claimDigest = sha256Hex(`${claimKey}|${claimValue}`);
    const proofToken = randomHex(32);
    const proofTokenHash = sha256Hex(proofToken);
    const expiresAt = nowPlusMinutes(expiresInMinutes);

    const proofRef = db.collection("credentialProofs").doc();
    const proofId = proofRef.id;
    const statementText =
      statement ||
      `Prueba de posesión generada sobre "${claimKey}" sin exponer el documento completo.`;

    const now = admin.firestore.FieldValue.serverTimestamp();
    await Promise.all([
      proofRef.set({
        id: proofId,
        candidateUid,
        companyUid,
        applicationId: applicationId || null,
        jobOfferId: jobOfferId || null,
        credentialId,
        claimKey,
        claimDigest,
        proofDigest,
        proofTokenHash,
        statement: statementText,
        disclosureMode: "zkp_selective",
        proofSchemaVersion: trace.proofSchemaVersion,
        verificationMethod: trace.verificationMethod,
        issuerDid: trace.issuerDid,
        credentialType: trace.credentialType,
        status: "active",
        verificationCount: 0,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        createdAt: now,
        updatedAt: now,
      }),
      db.collection("credentialProofShares").doc(proofId).set({
        id: proofId,
        proofId,
        candidateUid,
        companyUid,
        applicationId: applicationId || null,
        jobOfferId: jobOfferId || null,
        credentialId,
        claimKey,
        statement: statementText,
        disclosureMode: "zkp_selective",
        proofSchemaVersion: trace.proofSchemaVersion,
        verificationMethod: trace.verificationMethod,
        issuerDid: trace.issuerDid,
        credentialType: trace.credentialType,
        status: "active",
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        createdAt: now,
        updatedAt: now,
      }),
      logAuditEntry({
        action: "candidate_zkp_proof_created",
        actorUid: candidateUid,
        actorRole: "candidate",
        targetType: "credential_proof",
        targetId: proofId,
        companyId: companyUid,
        verificationMethod: trace.verificationMethod,
        issuerDid: trace.issuerDid,
        credentialType: trace.credentialType,
        proofSchemaVersion: trace.proofSchemaVersion,
        metadata: {
          applicationId: applicationId || null,
          credentialId,
          claimKey,
          disclosureMode: "zkp_selective",
          expiresInMinutes,
        },
      }),
    ]);

    return {
      proofId,
      proofToken,
      companyUid,
      applicationId: applicationId || null,
      disclosureMode: "zkp_selective",
      statement: statementText,
      proofSchemaVersion: trace.proofSchemaVersion,
      verificationMethod: trace.verificationMethod,
      issuerDid: trace.issuerDid,
      credentialType: trace.credentialType,
      expiresAt: expiresAt.toISOString(),
    };
  });

/**
 * Company/recruiter verifies a candidate proof by proofId + proofToken.
 * Returns only selective statement and verification status.
 */
export const verifySelectiveDisclosureProof = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    const proofId = asTrimmedString(data?.proofId);
    const proofToken = asTrimmedString(data?.proofToken);
    if (!proofId || !proofToken) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "proofId y proofToken son obligatorios.",
      );
    }

    const db = admin.firestore();
    const proofDoc = await db.collection("credentialProofs").doc(proofId).get();
    if (!proofDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Prueba no encontrada.");
    }
    const proof = asRecord(proofDoc.data());
    const companyUid = asTrimmedString(proof.companyUid);
    if (!companyUid) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "La prueba no tiene destinatario válido.",
      );
    }

    const actorUid = context.auth.uid;
    const actorScope = await assertCompanyOrRecruiterAccess({
      actorUid,
      companyUid,
    });

    const status = asTrimmedString(proof.status);
    if (status !== "active") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "La prueba no está activa.",
      );
    }

    const expiresAt = proof.expiresAt as admin.firestore.Timestamp | undefined;
    if (expiresAt && expiresAt.toDate().getTime() < Date.now()) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "La prueba está expirada.",
      );
    }

    const providedHash = sha256Hex(proofToken);
    const expectedHash = asTrimmedString(proof.proofTokenHash);
    if (!expectedHash || providedHash !== expectedHash) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Token de prueba inválido.",
      );
    }

    const verificationCountRaw = proof.verificationCount;
    const verificationCount =
      typeof verificationCountRaw === "number"
        ? verificationCountRaw
        : Number(verificationCountRaw) || 0;

    const trace = {
      proofSchemaVersion:
        asTrimmedString(proof.proofSchemaVersion) || DEFAULT_PROOF_SCHEMA_VERSION,
      verificationMethod: asTrimmedString(proof.verificationMethod) || null,
      issuerDid: asTrimmedString(proof.issuerDid) || null,
      credentialType: asTrimmedString(proof.credentialType) || null,
    };

    const now = admin.firestore.FieldValue.serverTimestamp();
    await Promise.all([
      db.collection("credentialProofs").doc(proofId).set(
        {
          verificationCount: verificationCount + 1,
          lastVerifiedBy: actorUid,
          lastVerifiedAt: now,
          updatedAt: now,
        },
        { merge: true },
      ),
      db.collection("credentialProofShares").doc(proofId).set(
        {
          verificationCount: verificationCount + 1,
          lastVerifiedBy: actorUid,
          lastVerifiedAt: now,
          updatedAt: now,
        },
        { merge: true },
      ),
      logAuditEntry({
        action: "candidate_zkp_proof_verified",
        actorUid,
        actorRole: actorScope === "company" ? "company" : "recruiter",
        targetType: "credential_proof",
        targetId: proofId,
        companyId: companyUid,
        verificationMethod: trace.verificationMethod,
        issuerDid: trace.issuerDid,
        credentialType: trace.credentialType,
        proofSchemaVersion: trace.proofSchemaVersion,
        metadata: {
          disclosureMode: asTrimmedString(proof.disclosureMode) || "zkp_selective",
          applicationId: asTrimmedString(proof.applicationId) || null,
          claimKey: asTrimmedString(proof.claimKey),
        },
      }),
    ]);

    const statement = asTrimmedString(proof.statement);
    const claimKey = asTrimmedString(proof.claimKey);
    return {
      verified: true,
      proofId,
      statement,
      claimKey,
      disclosureMode: asTrimmedString(proof.disclosureMode) || "zkp_selective",
      proofSchemaVersion: trace.proofSchemaVersion,
      verificationMethod: trace.verificationMethod,
      issuerDid: trace.issuerDid,
      credentialType: trace.credentialType,
      candidateUid: asTrimmedString(proof.candidateUid) || null,
      applicationId: asTrimmedString(proof.applicationId) || null,
      jobOfferId: asTrimmedString(proof.jobOfferId) || null,
      companyUid: asTrimmedString(proof.companyUid) || null,
      expiresAt: expiresAt?.toDate().toISOString() ?? null,
      verifiedAt: new Date().toISOString(),
    };
  });

/**
 * Candidate revokes an active proof before expiration.
 */
export const revokeSelectiveDisclosureProof = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    const proofId = asTrimmedString(data?.proofId);
    if (!proofId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "proofId es obligatorio.",
      );
    }

    const candidateUid = context.auth.uid;
    const db = admin.firestore();
    const proofRef = db.collection("credentialProofs").doc(proofId);
    const proofDoc = await proofRef.get();
    if (!proofDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Prueba no encontrada.");
    }
    const proof = asRecord(proofDoc.data());
    const ownerUid = asTrimmedString(proof.candidateUid);
    if (ownerUid !== candidateUid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Solo puedes revocar tus propias pruebas.",
      );
    }

    const revokedAtIso = new Date().toISOString();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const trace = {
      proofSchemaVersion:
        asTrimmedString(proof.proofSchemaVersion) || DEFAULT_PROOF_SCHEMA_VERSION,
      verificationMethod: asTrimmedString(proof.verificationMethod) || null,
      issuerDid: asTrimmedString(proof.issuerDid) || null,
      credentialType: asTrimmedString(proof.credentialType) || null,
    };

    await Promise.all([
      proofRef.set(
        {
          status: "revoked",
          revokedAt: now,
          revokedAtIso,
          updatedAt: now,
        },
        { merge: true },
      ),
      db.collection("credentialProofShares").doc(proofId).set(
        {
          status: "revoked",
          revokedAt: now,
          revokedAtIso,
          updatedAt: now,
        },
        { merge: true },
      ),
      logAuditEntry({
        action: "candidate_zkp_proof_revoked",
        actorUid: candidateUid,
        actorRole: "candidate",
        targetType: "credential_proof",
        targetId: proofId,
        companyId: asTrimmedString(proof.companyUid) || null,
        verificationMethod: trace.verificationMethod,
        issuerDid: trace.issuerDid,
        credentialType: trace.credentialType,
        proofSchemaVersion: trace.proofSchemaVersion,
        metadata: {
          revokedAtIso,
          applicationId: asTrimmedString(proof.applicationId) || null,
        },
      }),
    ]);

    return {
      success: true,
      proofId,
      revokedAt: revokedAtIso,
      proofSchemaVersion: trace.proofSchemaVersion,
    };
  });
