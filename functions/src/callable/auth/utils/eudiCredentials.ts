import * as admin from "firebase-admin";
import { VerifiedEudiPresentation } from "../../../utils/eudiCryptoVerifier";
import {
  JsonRecord,
  asRecord,
  asTrimmedString,
  normalizeIsoDate,
  sanitizeDocId,
  DEFAULT_PROOF_SCHEMA_VERSION,
  EUDI_PROOF_SCHEMA_VERSION,
} from "./eudiUtils";

export function buildCredentialId({
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

export function parseCredentialPayload(value: unknown): {
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

export function buildCredentialFromVerifiedPresentation(
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

export function resolveCredentialTrace(credential: JsonRecord): {
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

export async function upsertVerifiedCredential({
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
      proofSchemaVersion: credential.proofSchemaVersion ?? EUDI_PROOF_SCHEMA_VERSION,
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
