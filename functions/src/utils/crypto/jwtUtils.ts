import * as crypto from "crypto";
import * as functions from "firebase-functions/v1";
import { asRecord } from "../typeGuards";

export function sha256Hex(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

export function decodeBase64Url(segment: string): Buffer {
  const normalized = segment.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(
    normalized.length + ((4 - (normalized.length % 4)) % 4),
    "=",
  );
  return Buffer.from(padded, "base64");
}

export function parseJsonSegment(segment: string, fieldName: string): Record<string, unknown> {
  try {
    const decoded = decodeBase64Url(segment).toString("utf8");
    const parsed = JSON.parse(decoded) as unknown;
    return asRecord(parsed);
  } catch (_error) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `El token de presentation contiene un ${fieldName} inválido.`,
    );
  }
}

export function verifyJwtSignature({
  alg,
  signingInput,
  signature,
  publicKey,
}: {
  alg: string;
  signingInput: string;
  signature: Buffer;
  publicKey: string | crypto.KeyObject;
}): boolean {
  if (alg === "RS256") {
    return crypto.verify(
      "RSA-SHA256",
      Buffer.from(signingInput, "utf8"),
      publicKey,
      signature,
    );
  }

  if (alg === "ES256") {
    return crypto.verify(
      "sha256",
      Buffer.from(signingInput, "utf8"),
      publicKey,
      signature,
    );
  }

  throw new functions.https.HttpsError(
    "permission-denied",
    `Algoritmo de firma no permitido para EUDI: ${alg || "unknown"}.`,
  );
}
