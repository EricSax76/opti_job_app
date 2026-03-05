import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import {
  buildCanonicalAiConsentPayload,
  computeAiConsentHash,
  normalizeAiConsentScopes,
  normalizeConsentText,
  normalizeConsentTextVersion,
} from "../../utils/aiConsent";
import { asTrimmedString, ttlDate } from "./utils/complianceUtils";

const CONSENT_TTL_DAYS = 365 * 3;

export const grantAiConsent = onCall({ region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const candidateUid = request.auth.uid;
  const companyId = asTrimmedString(
    request.data?.companyId ?? request.data?.companyUid,
  );
  const type = asTrimmedString(request.data?.type || "ai_granular") || "ai_granular";
  const scopes = normalizeAiConsentScopes(request.data?.scope);
  const consentTextVersion = normalizeConsentTextVersion(
    request.data?.consentTextVersion,
  );
  const consentText = normalizeConsentText(
    request.data?.consentText ?? request.data?.consentTextSnapshot,
  );

  if (!companyId) {
    throw new HttpsError("invalid-argument", "companyId es obligatorio.");
  }
  if (scopes.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "scope debe incluir al menos ai_interview o ai_test.",
    );
  }
  if (!consentTextVersion) {
    throw new HttpsError("invalid-argument", "consentTextVersion es obligatorio.");
  }
  if (!consentText) {
    throw new HttpsError("invalid-argument", "consentText es obligatorio.");
  }

  const db = getFirestore();
  const companyDoc = await db.collection("companies").doc(companyId).get();
  if (!companyDoc.exists) {
    throw new HttpsError(
      "failed-precondition",
      "No existe la empresa asociada al consentimiento.",
    );
  }

  const canonicalPayload = buildCanonicalAiConsentPayload({
    candidateUid,
    companyId,
    scope: scopes,
    consentTextVersion,
    consentText,
  });
  const consentHash = computeAiConsentHash(canonicalPayload);

  const docRef = db.collection("consentRecords").doc();
  await docRef.set({
    id: docRef.id,
    candidateUid,
    companyId,
    type,
    granted: true,
    legalBasis: "consent",
    informationNoticeVersion: consentTextVersion,
    consentTextVersion,
    consentTextSnapshot: consentText,
    scope: scopes,
    scopeKey: scopes.join("|"),
    consentHash,
    consentHashPayload: canonicalPayload,
    immutable: true,
    status: "granted",
    grantedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromDate(ttlDate(CONSENT_TTL_DAYS)),
    revokedAt: null,
  });

  return {
    ok: true,
    id: docRef.id,
    candidateUid,
    companyId,
    type,
    granted: true,
    consentHash,
    consentTextVersion,
    scope: scopes,
  };
});

