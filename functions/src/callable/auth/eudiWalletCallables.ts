import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

type JsonRecord = Record<string, unknown>;

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
}: {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  metadata: JsonRecord;
}): Promise<void> {
  await admin.firestore().collection("auditLogs").add({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
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
      issuedAt: credential.issuedAt,
      expiresAt: credential.expiresAt,
      verified: true,
      source: "eudi_wallet",
      metadata: credential.metadata,
      updatedBy: actorUid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return credentialId;
}

/**
 * MVP EUDI Wallet sign-in/up for candidates.
 * Creates or links candidate by wallet subject and returns Firebase custom token.
 */
export const signInWithEudiWallet = functions
  .region("europe-west1")
  .https.onCall(async (data, _context) => {
    const walletSubject = asTrimmedString(data?.walletSubject);
    const email = normalizeEmail(data?.email);
    const fullName = asTrimmedString(data?.fullName);
    const countryCode = asTrimmedString(data?.countryCode || "ES") || "ES";
    const assuranceLevel =
      asTrimmedString(data?.assuranceLevel || "substantial") ||
      "substantial";
    const credential = parseCredentialPayload(data?.credential);

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

    const existingCandidateData = (candidateDoc.data() as JsonRecord | undefined) ?? {};

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
    if (credential != null) {
      importedCredentialId = await upsertVerifiedCredential({
        candidateUid,
        credential,
        actorUid: candidateUid,
      });
    }

    await logAuditEntry({
      action: "candidate_wallet_sign_in",
      actorUid: candidateUid,
      actorRole: "candidate",
      targetType: "candidate",
      targetId: candidateUid,
      metadata: {
        provider: "eudi_wallet",
        importedCredential: importedCredentialId != null,
        importedCredentialId,
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
    };
  });

/**
 * Import a verified EUDI credential for authenticated candidate.
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
    const credential = parseCredentialPayload(data?.credential);
    if (credential == null) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Credencial inválida. type, title e issuer son obligatorios.",
      );
    }

    const db = admin.firestore();
    const candidateDoc = await db.collection("candidates").doc(candidateUid).get();
    if (!candidateDoc.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No existe un perfil candidato para el usuario autenticado.",
      );
    }

    const credentialId = await upsertVerifiedCredential({
      candidateUid,
      credential,
      actorUid: candidateUid,
    });

    await logAuditEntry({
      action: "candidate_wallet_credential_imported",
      actorUid: candidateUid,
      actorRole: "candidate",
      targetType: "verified_credential",
      targetId: credentialId,
      metadata: {
        provider: "eudi_wallet",
        type: credential.type,
      },
    });

    return {
      candidateUid,
      credentialId,
      verified: true,
    };
  });
