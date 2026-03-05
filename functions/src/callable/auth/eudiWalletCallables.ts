import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

import {
  verifyEudiPresentation,
  type VerifiedEudiPresentation,
} from "../../utils/eudiCryptoVerifier";

type JsonRecord = Record<string, unknown>;

const EUDI_SIGN_IN_AUDIENCE = "opti-job-app:eudi-signin";
const EUDI_IMPORT_AUDIENCE = "opti-job-app:eudi-import";
const EUDI_PROOF_SCHEMA_VERSION = "2026.1";

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

function normalizeEmail(value: unknown): string {
  return asTrimmedString(value).toLowerCase();
}

function normalizeIsoDate(value: unknown): string | null {
  const raw = asTrimmedString(value);
  if (!raw) return null;
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString();
}

function sanitizeDocId(raw: string): string {
  const normalized = raw
    .toLowerCase()
    .replace(/[^a-z0-9_-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 110);
  return normalized || `cred-${Date.now()}`;
}

function buildCredentialId({
  type,
  title,
  issuer,
  issuedAt,
}: {
  type: string;
  title: string;
  issuer: string;
  issuedAt: string | null;
}): string {
  const issuedAtKey = issuedAt ? issuedAt.slice(0, 10) : "unknown";
  return sanitizeDocId(`${type}-${issuer}-${title}-${issuedAtKey}`);
}

function parseCredentialPayload(value: unknown): {
  type: string;
  title: string;
  issuer: string;
  issuedAt: string | null;
  expiresAt: string | null;
  metadata: JsonRecord;
} | null {
  const raw = asRecord(value);
  const type = asTrimmedString(raw.type);
  const title = asTrimmedString(raw.title);
  const issuer = asTrimmedString(raw.issuer);
  if (!type || !title || !issuer) {
    return null;
  }

  return {
    type,
    title,
    issuer,
    issuedAt: normalizeIsoDate(raw.issuedAt),
    expiresAt: normalizeIsoDate(raw.expiresAt),
    metadata: asRecord(raw.metadata),
  };
}

async function logAuditEntry({
  action,
  actorUid,
  actorRole,
  targetType,
  targetId,
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
    verificationMethod: verificationMethod ?? null,
    issuerDid: issuerDid ?? null,
    credentialType: credentialType ?? null,
    proofSchemaVersion: proofSchemaVersion ?? null,
    metadata,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function resolveOrCreateAuthUser({
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

async function upsertVerifiedCredential({
  candidateUid,
  credential,
  actorUid,
}: {
  candidateUid: string;
  credential: {
    type: string;
    title: string;
    issuer: string;
    issuedAt: string | null;
    expiresAt: string | null;
    metadata: JsonRecord;
    verificationMethod?: string | null;
    issuerDid?: string | null;
    credentialType?: string | null;
    proofSchemaVersion?: string | null;
    verifiablePresentationHash?: string | null;
  };
  actorUid: string;
}): Promise<string> {
  const db = admin.firestore();
  const credentialId = buildCredentialId(credential);
  const credentialRef = db
    .collection("candidates")
    .doc(candidateUid)
    .collection("verifiedCredentials")
    .doc(credentialId);

  await credentialRef.set(
    {
      id: credentialId,
      type: credential.type,
      title: credential.title,
      issuer: credential.issuer,
      issuerDid: credential.issuerDid ?? credential.issuer,
      credentialType: credential.credentialType ?? credential.type,
      verificationMethod: credential.verificationMethod ?? null,
      proofSchemaVersion:
        credential.proofSchemaVersion ?? EUDI_PROOF_SCHEMA_VERSION,
      verifiablePresentationHash: credential.verifiablePresentationHash ?? null,
      issuedAt: credential.issuedAt,
      expiresAt: credential.expiresAt,
      verified: true,
      source: "eudi_wallet_native",
      metadata: credential.metadata,
      updatedBy: actorUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      cryptographicallyVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return credentialId;
}

function buildCredentialFromVerifiedPresentation(
  verifiedPresentation: VerifiedEudiPresentation,
): {
  type: string;
  title: string;
  issuer: string;
  issuedAt: string | null;
  expiresAt: string | null;
  metadata: JsonRecord;
  verificationMethod: string;
  issuerDid: string;
  credentialType: string;
  proofSchemaVersion: string;
  verifiablePresentationHash: string;
} {
  return {
    type: verifiedPresentation.credentialType,
    title: verifiedPresentation.credentialTitle,
    issuer: verifiedPresentation.issuerDid,
    issuedAt: verifiedPresentation.issuedAt,
    expiresAt: verifiedPresentation.expiresAt,
    verificationMethod: verifiedPresentation.verificationMethod,
    issuerDid: verifiedPresentation.issuerDid,
    credentialType: verifiedPresentation.credentialType,
    proofSchemaVersion: verifiedPresentation.proofSchemaVersion,
    verifiablePresentationHash: verifiedPresentation.verifiablePresentationHash,
    metadata: {
      ...verifiedPresentation.metadata,
      audience: verifiedPresentation.audience,
      proofSchemaVersion: verifiedPresentation.proofSchemaVersion,
      issuerDid: verifiedPresentation.issuerDid,
      verificationMethod: verifiedPresentation.verificationMethod,
      credentialType: verifiedPresentation.credentialType,
      verifiablePresentationHash: verifiedPresentation.verifiablePresentationHash,
    },
  };
}

function resolveExpectedAudience(
  data: unknown,
  fallbackAudience: string,
): string {
  const payload = asRecord(data);
  const requestedAudience = asTrimmedString(payload.expectedAudience);
  if (requestedAudience) return requestedAudience;
  return fallbackAudience;
}

/**
 * EUDI Wallet sign-in/up for candidates.
 * Creates or links candidate by wallet subject and returns Firebase custom token.
 * If a verifiablePresentation is present, identity fields are derived from crypto-validated claims.
 */
export const signInWithEudiWallet = functions
  .region("europe-west1")
  .https.onCall(async (data, _context) => {
    const expectedAudience = resolveExpectedAudience(data, EUDI_SIGN_IN_AUDIENCE);
    const providedWalletSubject = asTrimmedString(data?.walletSubject);
    const providedEmail = normalizeEmail(data?.email);
    const providedFullName = asTrimmedString(data?.fullName);
    const providedCountryCode = asTrimmedString(data?.countryCode || "ES") || "ES";
    const providedAssuranceLevel =
      asTrimmedString(data?.assuranceLevel || "substantial") || "substantial";

    const legacyCredential = parseCredentialPayload(data?.credential);
    const hasPresentation = data?.verifiablePresentation != null;

    let verifiedPresentation: VerifiedEudiPresentation | null = null;
    if (hasPresentation) {
      verifiedPresentation = verifyEudiPresentation({
        verifiablePresentation: data?.verifiablePresentation,
        expectedAudience,
        proofSchemaVersion:
          asTrimmedString(data?.proofSchemaVersion) || EUDI_PROOF_SCHEMA_VERSION,
      });
    }

    if (legacyCredential != null && verifiedPresentation == null) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No se puede importar credencial EUDI sin verificación criptográfica (verifiablePresentation).",
      );
    }

    const walletSubject =
      verifiedPresentation?.walletSubject || providedWalletSubject;
    const email = normalizeEmail(
      verifiedPresentation?.email || providedEmail,
    );
    const fullName =
      asTrimmedString(verifiedPresentation?.fullName || providedFullName);
    const countryCode =
      asTrimmedString(verifiedPresentation?.countryCode || providedCountryCode) ||
      "ES";
    const assuranceLevel =
      asTrimmedString(
        verifiedPresentation?.assuranceLevel || providedAssuranceLevel,
      ) || "substantial";

    if (!walletSubject || !email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "walletSubject y email son obligatorios para iniciar con EUDI Wallet.",
      );
    }

    const db = admin.firestore();

    let candidateUid = "";

    const linkedCandidateSnapshot = await db
      .collection("candidates")
      .where("wallet_subject", "==", walletSubject)
      .limit(1)
      .get();

    if (!linkedCandidateSnapshot.empty) {
      candidateUid = linkedCandidateSnapshot.docs[0].id;
    } else {
      const userRecord = await resolveOrCreateAuthUser({ email, fullName });
      candidateUid = userRecord.uid;

      const companyDoc = await db.collection("companies").doc(candidateUid).get();
      if (companyDoc.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "El email está asociado a una cuenta de empresa. Usa acceso de empresa.",
        );
      }
    }

    const candidateRef = db.collection("candidates").doc(candidateUid);
    const candidateDoc = await candidateRef.get();

    const existingCandidateData =
      (candidateDoc.data() as JsonRecord | undefined) ?? {};

    const candidateData: JsonRecord = {
      id: existingCandidateData.id ?? Date.now(),
      uid: candidateUid,
      role: "candidate",
      name: fullName,
      email,
      onboarding_completed: existingCandidateData.onboarding_completed ?? false,
      auth_provider: "eudi_wallet",
      wallet_subject: walletSubject,
      wallet_assurance_level: assuranceLevel,
      wallet_country_code: countryCode,
      wallet_linked_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!candidateDoc.exists) {
      candidateData.created_at = admin.firestore.FieldValue.serverTimestamp();
      candidateData.last_name = "";
    }

    await candidateRef.set(candidateData, { merge: true });

    let importedCredentialId: string | null = null;
    if (verifiedPresentation != null) {
      importedCredentialId = await upsertVerifiedCredential({
        candidateUid,
        credential: buildCredentialFromVerifiedPresentation(verifiedPresentation),
        actorUid: candidateUid,
      });
    }

    await logAuditEntry({
      action: "candidate_wallet_sign_in",
      actorUid: candidateUid,
      actorRole: "candidate",
      targetType: "candidate",
      targetId: candidateUid,
      verificationMethod: verifiedPresentation?.verificationMethod ?? null,
      issuerDid: verifiedPresentation?.issuerDid ?? null,
      credentialType: verifiedPresentation?.credentialType ?? null,
      proofSchemaVersion:
        verifiedPresentation?.proofSchemaVersion ?? EUDI_PROOF_SCHEMA_VERSION,
      metadata: {
        provider: "eudi_wallet",
        importedCredential: importedCredentialId != null,
        importedCredentialId,
        cryptographicallyValidated: verifiedPresentation != null,
        audience: expectedAudience,
      },
    });

    const customToken = await admin.auth().createCustomToken(candidateUid, {
      authProvider: "eudi_wallet",
    });

    return {
      candidateUid,
      customToken,
      importedCredentialId,
      provider: "eudi_wallet",
      cryptographicallyValidated: verifiedPresentation != null,
      verificationMethod: verifiedPresentation?.verificationMethod ?? null,
      issuerDid: verifiedPresentation?.issuerDid ?? null,
      credentialType: verifiedPresentation?.credentialType ?? null,
      proofSchemaVersion:
        verifiedPresentation?.proofSchemaVersion ?? EUDI_PROOF_SCHEMA_VERSION,
    };
  });

/**
 * Import a verified EUDI credential for authenticated candidate.
 * Requires a cryptographically validated verifiablePresentation.
 */
export const importEudiCredential = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    const candidateUid = context.auth.uid;
    const expectedAudience = resolveExpectedAudience(data, EUDI_IMPORT_AUDIENCE);
    const proofSchemaVersion =
      asTrimmedString(data?.proofSchemaVersion) || EUDI_PROOF_SCHEMA_VERSION;

    const verifiedPresentation = verifyEudiPresentation({
      verifiablePresentation: data?.verifiablePresentation,
      expectedAudience,
      proofSchemaVersion,
    });

    const db = admin.firestore();
    const candidateRef = db.collection("candidates").doc(candidateUid);
    const candidateDoc = await candidateRef.get();
    if (!candidateDoc.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No existe un perfil candidato para el usuario autenticado.",
      );
    }

    const candidateData = asRecord(candidateDoc.data());
    const existingWalletSubject = asTrimmedString(candidateData.wallet_subject);
    if (
      existingWalletSubject &&
      existingWalletSubject !== verifiedPresentation.walletSubject
    ) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "La presentación EUDI no corresponde al wallet vinculado en esta cuenta.",
      );
    }

    await candidateRef.set(
      {
        wallet_subject: verifiedPresentation.walletSubject,
        wallet_assurance_level: verifiedPresentation.assuranceLevel,
        wallet_country_code: verifiedPresentation.countryCode,
        wallet_linked_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const credentialId = await upsertVerifiedCredential({
      candidateUid,
      credential: buildCredentialFromVerifiedPresentation(verifiedPresentation),
      actorUid: candidateUid,
    });

    await logAuditEntry({
      action: "candidate_wallet_credential_imported",
      actorUid: candidateUid,
      actorRole: "candidate",
      targetType: "verified_credential",
      targetId: credentialId,
      verificationMethod: verifiedPresentation.verificationMethod,
      issuerDid: verifiedPresentation.issuerDid,
      credentialType: verifiedPresentation.credentialType,
      proofSchemaVersion: verifiedPresentation.proofSchemaVersion,
      metadata: {
        provider: "eudi_wallet",
        type: verifiedPresentation.credentialType,
        audience: expectedAudience,
        cryptographicallyValidated: true,
      },
    });

    return {
      candidateUid,
      credentialId,
      verified: true,
      cryptographicallyValidated: true,
      verificationMethod: verifiedPresentation.verificationMethod,
      issuerDid: verifiedPresentation.issuerDid,
      credentialType: verifiedPresentation.credentialType,
      proofSchemaVersion: verifiedPresentation.proofSchemaVersion,
    };
  });
