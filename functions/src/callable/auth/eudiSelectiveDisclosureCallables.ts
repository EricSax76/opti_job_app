import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {
  asTrimmedString,
  asRecord,
  sha256Hex,
  randomHex,
  nowPlusMinutes,
  DEFAULT_PROOF_SCHEMA_VERSION,
} from "./utils/eudiUtils";
import {
  resolveCompanyUidFromApplication,
  assertCompanyOrRecruiterAccess,
} from "./utils/eudiAccess";
import { logAuditEntry } from "./utils/eudiAudit";
import { resolveCredentialTrace } from "./utils/eudiCredentials";
import { ensureCallableResponseContract } from "../../utils/contractConventions";

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

    return ensureCallableResponseContract(
      {
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
      },
      { callableName: "createSelectiveDisclosureProof" },
    );
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
    return ensureCallableResponseContract(
      {
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
      },
      { callableName: "verifySelectiveDisclosureProof" },
    );
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

    return ensureCallableResponseContract(
      {
        success: true,
        proofId,
        revokedAt: revokedAtIso,
        proofSchemaVersion: trace.proofSchemaVersion,
      },
      { callableName: "revokeSelectiveDisclosureProof" },
    );
  });
