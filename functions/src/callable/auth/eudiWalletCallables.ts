import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

import {
  verifyEudiPresentation,
  type VerifiedEudiPresentation,
} from "../../utils/eudiCryptoVerifier";

import {
  asTrimmedString,
  asRecord,
  normalizeEmail,
  resolveExpectedAudience,
  JsonRecord,
  EUDI_PROOF_SCHEMA_VERSION,
} from "./utils/eudiUtils";
import { resolveOrCreateAuthUser } from "./utils/eudiAccess";
import { logAuditEntry } from "./utils/eudiAudit";
import {
  buildCredentialFromVerifiedPresentation,
  parseCredentialPayload,
  upsertVerifiedCredential,
} from "./utils/eudiCredentials";

const EUDI_SIGN_IN_AUDIENCE = "opti-job-app:eudi-signin";
const EUDI_IMPORT_AUDIENCE = "opti-job-app:eudi-import";

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
