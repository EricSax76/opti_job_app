import { asRecord, asTrimmedString, JsonRecord } from '../typeGuards';
import { parseJsonSegment } from './jwtUtils';

export function normalizeIsoDate(value: unknown): string | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    const millis = value > 9999999999 ? value : value * 1000;
    return new Date(millis).toISOString();
  }

  const raw = asTrimmedString(value);
  if (!raw) return null;

  if (/^\d+$/.test(raw)) {
    const parsedInt = Number(raw);
    if (Number.isFinite(parsedInt)) {
      const millis = parsedInt > 9999999999 ? parsedInt : parsedInt * 1000;
      return new Date(millis).toISOString();
    }
  }

  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) return null;
  return parsed.toISOString();
}

export function resolveCredentialObject(jwtPayload: JsonRecord): JsonRecord {
  const directVc = asRecord(jwtPayload.vc);
  if (Object.keys(directVc).length > 0) return directVc;

  const directCredential = asRecord(jwtPayload.credential);
  if (Object.keys(directCredential).length > 0) return directCredential;

  const vp = asRecord(jwtPayload.vp);
  const verifiableCredential = vp.verifiableCredential;
  if (Array.isArray(verifiableCredential) && verifiableCredential.length > 0) {
    const first = verifiableCredential[0];
    if (typeof first === "string") {
      const parts = first.split(".");
      if (parts.length === 3) {
        return parseJsonSegment(parts[1], "payload de verifiableCredential");
      }
      return {};
    }
    return asRecord(first);
  }

  return {};
}

export function resolveCredentialType(
  credential: JsonRecord,
  jwtPayload: JsonRecord,
): string {
  const credentialType = credential.type;
  if (Array.isArray(credentialType)) {
    const normalized = credentialType
      .map((item) => asTrimmedString(item))
      .filter((item) => item.length > 0);
    const specific = normalized.find((item) => item !== "VerifiableCredential");
    if (specific) return specific;
    if (normalized.length > 0) return normalized[0];
  }

  const single = asTrimmedString(credentialType);
  if (single) return single;

  const payloadType = asTrimmedString(jwtPayload.credentialType);
  if (payloadType) return payloadType;

  return "verifiable_credential";
}

export function resolveCredentialSubject(
  credential: JsonRecord,
  jwtPayload: JsonRecord,
): JsonRecord {
  const subject = credential.credentialSubject;
  if (Array.isArray(subject) && subject.length > 0) {
    return asRecord(subject[0]);
  }
  const single = asRecord(subject);
  if (Object.keys(single).length > 0) return single;

  return asRecord(jwtPayload.credentialSubject);
}

export function resolveIssuerDid(credential: JsonRecord, jwtPayload: JsonRecord): string {
  const vcIssuerRaw = credential.issuer;
  if (typeof vcIssuerRaw === "string") {
    const direct = vcIssuerRaw.trim();
    if (direct) return direct;
  }
  const vcIssuerObject = asRecord(vcIssuerRaw);
  const vcIssuerId = asTrimmedString(vcIssuerObject.id);
  if (vcIssuerId) return vcIssuerId;

  return asTrimmedString(jwtPayload.iss);
}

export function resolveVerificationMethod(jwtHeader: JsonRecord): string {
  const kid = asTrimmedString(jwtHeader.kid);
  if (kid) return kid;

  const jwk = asRecord(jwtHeader.jwk);
  const jwkKid = asTrimmedString(jwk.kid);
  if (jwkKid) return jwkKid;

  const alg = asTrimmedString(jwtHeader.alg);
  return alg ? `jws:${alg}` : "jws:unknown";
}
