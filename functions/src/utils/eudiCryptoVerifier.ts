import * as crypto from "crypto";
import * as functions from "firebase-functions/v1";
import { asRecord, asTrimmedString, asStringArray, JsonRecord } from "./typeGuards";
import {
  decodeBase64Url,
  parseJsonSegment,
  verifyJwtSignature,
  sha256Hex,
} from "./crypto/jwtUtils";
import {
  normalizeIsoDate,
  resolveCredentialObject,
  resolveCredentialType,
  resolveCredentialSubject,
  resolveIssuerDid,
  resolveVerificationMethod,
} from "./crypto/eudiParsers";

export type TrustedIssuerRegistry = Record<string, TrustedIssuerConfig>;

export interface TrustedIssuerConfig {
  publicPem?: string;
  publicJwk?: JsonRecord;
  allowedAudiences?: string[];
  allowedAlgorithms?: string[];
  active?: boolean;
}

export interface VerifyEudiPresentationInput {
  verifiablePresentation: unknown;
  expectedAudience: string;
  proofSchemaVersion: string;
  trustedIssuers?: TrustedIssuerRegistry;
}

export interface VerifiedEudiPresentation {
  walletSubject: string;
  email: string;
  fullName: string;
  countryCode: string;
  assuranceLevel: string;
  issuerDid: string;
  verificationMethod: string;
  credentialType: string;
  credentialTitle: string;
  issuedAt: string | null;
  expiresAt: string | null;
  proofSchemaVersion: string;
  verifiablePresentationJwt: string;
  verifiablePresentationHash: string;
  audience: string[];
  metadata: JsonRecord;
}

let cachedRegistryRaw: string | null = null;
let cachedRegistry: TrustedIssuerRegistry | null = null;

function extractJwtFromPresentation(value: unknown): string {
  if (typeof value === "string") {
    const raw = value.trim();
    if (raw.length > 0) return raw;
  }

  const payload = asRecord(value);
  const directCandidates = [
    payload.verifiablePresentation,
    payload.verifiablePresentationJwt,
    payload.presentationJwt,
    payload.vpJwt,
    payload.jwt,
    payload.vp_token,
  ];
  for (const candidate of directCandidates) {
    const token = asTrimmedString(candidate);
    if (token) return token;
  }

  const proof = asRecord(payload.proof);
  const proofJwt = asTrimmedString(proof.jwt);
  if (proofJwt) return proofJwt;

  throw new functions.https.HttpsError(
    "invalid-argument",
    "Debes enviar una verifiablePresentation JWT válida.",
  );
}

function parseAudience(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value
      .map((item) => asTrimmedString(item))
      .filter((item) => item.length > 0);
  }
  const single = asTrimmedString(value);
  return single ? [single] : [];
}

function parseTrustedIssuersFromEnv(): TrustedIssuerRegistry {
  const raw = process.env.EUDI_TRUSTED_ISSUERS_JSON ?? "";
  const trimmed = raw.trim();

  if (!trimmed) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Falta EUDI_TRUSTED_ISSUERS_JSON para validar presentaciones EUDI.",
    );
  }

  if (cachedRegistryRaw === trimmed && cachedRegistry != null) {
    return cachedRegistry;
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(trimmed);
  } catch (_error) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "EUDI_TRUSTED_ISSUERS_JSON no es un JSON válido.",
    );
  }

  const registryRecord = asRecord(parsed);
  if (Object.keys(registryRecord).length === 0) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "EUDI_TRUSTED_ISSUERS_JSON está vacío.",
    );
  }

  const registry: TrustedIssuerRegistry = {};
  for (const [issuerDid, configRaw] of Object.entries(registryRecord)) {
    const config = asRecord(configRaw);
    const publicPem = asTrimmedString(config.publicPem);
    const publicJwk = asRecord(config.publicJwk);
    const normalizedConfig: TrustedIssuerConfig = {
      publicPem: publicPem || undefined,
      publicJwk: Object.keys(publicJwk).length > 0 ? publicJwk : undefined,
      allowedAudiences: asStringArray(config.allowedAudiences),
      allowedAlgorithms: asStringArray(config.allowedAlgorithms),
      active: config.active === false ? false : true,
    };

    registry[issuerDid] = normalizedConfig;
  }

  cachedRegistryRaw = trimmed;
  cachedRegistry = registry;
  return registry;
}

function resolveTrustedIssuers(
  override?: TrustedIssuerRegistry,
): TrustedIssuerRegistry {
  if (override != null) return override;
  return parseTrustedIssuersFromEnv();
}

function resolvePublicKey(issuerConfig: TrustedIssuerConfig): string | crypto.KeyObject {
  const pem = asTrimmedString(issuerConfig.publicPem);
  if (pem) return pem;

  const jwk = asRecord(issuerConfig.publicJwk);
  if (Object.keys(jwk).length > 0) {
    return crypto.createPublicKey({
      key: jwk as crypto.JsonWebKey,
      format: "jwk",
    });
  }

  throw new functions.https.HttpsError(
    "failed-precondition",
    "Issuer EUDI sin clave pública configurada.",
  );
}

function ensureAudience({
  expectedAudience,
  tokenAudience,
  issuerConfig,
}: {
  expectedAudience: string;
  tokenAudience: string[];
  issuerConfig: TrustedIssuerConfig;
}): void {
  if (!tokenAudience.includes(expectedAudience)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "La audiencia de la presentación EUDI no coincide.",
    );
  }

  const allowedAudiences = issuerConfig.allowedAudiences ?? [];
  if (
    allowedAudiences.length > 0 &&
    !allowedAudiences.includes(expectedAudience)
  ) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "El issuer EUDI no está autorizado para esta audiencia.",
    );
  }
}

function ensureExpiration({
  jwtPayload,
  credential,
}: {
  jwtPayload: JsonRecord;
  credential: JsonRecord;
}): string {
  const jwtExpIso = normalizeIsoDate(jwtPayload.exp);
  const credentialExpIso = normalizeIsoDate(
    credential.expirationDate ?? credential.validUntil,
  );

  const effectiveExp = jwtExpIso || credentialExpIso;
  if (!effectiveExp) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "La verifiable presentation EUDI no incluye exp válido.",
    );
  }

  if (new Date(effectiveExp).getTime() < Date.now()) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "La verifiable presentation EUDI está expirada.",
    );
  }

  return effectiveExp;
}

export function verifyEudiPresentation({
  verifiablePresentation,
  expectedAudience,
  proofSchemaVersion,
  trustedIssuers,
}: VerifyEudiPresentationInput): VerifiedEudiPresentation {
  const vpToken = extractJwtFromPresentation(verifiablePresentation);
  const parts = vpToken.split(".");
  if (parts.length !== 3) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "La verifiable presentation debe ser un JWT con 3 segmentos.",
    );
  }

  const [headerSegment, payloadSegment, signatureSegment] = parts;
  const jwtHeader = parseJsonSegment(headerSegment, "header");
  const jwtPayload = parseJsonSegment(payloadSegment, "payload");
  const issuerDid = asTrimmedString(jwtPayload.iss);
  if (!issuerDid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "La verifiable presentation no incluye issuer (iss).",
    );
  }

  const registry = resolveTrustedIssuers(trustedIssuers);
  const issuerConfig = registry[issuerDid];
  if (issuerConfig == null || issuerConfig.active === false) {
    throw new functions.https.HttpsError(
      "permission-denied",
      `Issuer EUDI no confiable: ${issuerDid}`,
    );
  }

  const alg = asTrimmedString(jwtHeader.alg);
  const allowedAlgorithms = issuerConfig.allowedAlgorithms ?? [];
  if (allowedAlgorithms.length > 0 && !allowedAlgorithms.includes(alg)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      `Algoritmo ${alg || "unknown"} no autorizado para issuer EUDI.`,
    );
  }

  const signature = decodeBase64Url(signatureSegment);
  const signingInput = `${headerSegment}.${payloadSegment}`;
  const publicKey = resolvePublicKey(issuerConfig);
  const signatureValid = verifyJwtSignature({
    alg,
    signingInput,
    signature,
    publicKey,
  });
  if (!signatureValid) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Firma inválida en verifiable presentation EUDI.",
    );
  }

  const tokenAudience = parseAudience(jwtPayload.aud);
  ensureAudience({
    expectedAudience,
    tokenAudience,
    issuerConfig,
  });

  const credential = resolveCredentialObject(jwtPayload);
  const credentialSubject = resolveCredentialSubject(credential, jwtPayload);
  const resolvedIssuerDid = resolveIssuerDid(credential, jwtPayload);
  const walletSubject =
    asTrimmedString(credentialSubject.id) || asTrimmedString(jwtPayload.sub);
  if (!walletSubject) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "No se pudo resolver walletSubject/sub desde la presentación EUDI.",
    );
  }

  const expiresAt = ensureExpiration({ jwtPayload, credential });

  const credentialType = resolveCredentialType(credential, jwtPayload);
  const credentialTitle =
    asTrimmedString(credentialSubject.title) ||
    asTrimmedString(credentialSubject.name) ||
    asTrimmedString(credential.name) ||
    credentialType;

  const issuedAt =
    normalizeIsoDate(credential.issuanceDate ?? credential.validFrom) ||
    normalizeIsoDate(jwtPayload.iat);

  const metadata: JsonRecord = {
    audience: tokenAudience,
    presentationIssuer: issuerDid,
    presentationSubject: asTrimmedString(jwtPayload.sub),
    credentialSubject: credentialSubject,
    vcId: asTrimmedString(credential.id) || null,
  };

  const email = asTrimmedString(credentialSubject.email).toLowerCase();
  const fullName =
    asTrimmedString(credentialSubject.fullName) ||
    asTrimmedString(credentialSubject.name) ||
    asTrimmedString(jwtPayload.name);

  const countryCodeRaw =
    asTrimmedString(credentialSubject.countryCode) ||
    asTrimmedString(jwtPayload.countryCode) ||
    "ES";

  const assuranceLevel =
    asTrimmedString(jwtPayload.assuranceLevel) ||
    asTrimmedString(credentialSubject.assuranceLevel) ||
    "substantial";

  return {
    walletSubject,
    email,
    fullName,
    countryCode: countryCodeRaw.toUpperCase(),
    assuranceLevel,
    issuerDid: resolvedIssuerDid || issuerDid,
    verificationMethod: resolveVerificationMethod(jwtHeader),
    credentialType,
    credentialTitle,
    issuedAt,
    expiresAt,
    proofSchemaVersion,
    verifiablePresentationJwt: vpToken,
    verifiablePresentationHash: sha256Hex(vpToken),
    audience: tokenAudience,
    metadata,
  };
}

export function __resetTrustedIssuerCacheForTests(): void {
  cachedRegistryRaw = null;
  cachedRegistry = null;
}
