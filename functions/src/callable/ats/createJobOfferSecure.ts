import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { ValidationError, validateJobOffer } from "../../utils/validation";
import {
  JsonRecord,
  asNullableString,
  asTrimmedString,
  toFiniteNumber,
  validateSalary,
} from "./utils/salaryValidation";
import { resolveActorCompanyUid } from "./utils/atsAccess";

function pickPipelineArray(value: unknown): unknown[] | undefined {
  return Array.isArray(value) ? value : undefined;
}

function asJsonRecord(value: unknown): JsonRecord | null {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as JsonRecord;
}

export const createJobOfferSecure = onCall({ region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const payload = (request.data ?? {}) as JsonRecord;
  const title = asTrimmedString(payload.title);
  const description = asTrimmedString(payload.description);
  const location = asTrimmedString(payload.location);
  const requestedCompanyUid = asTrimmedString(
    payload.company_uid ?? payload.companyUid ?? payload.owner_uid,
  );

  if (!title || !description || !location) {
    throw new HttpsError(
      "invalid-argument",
      "title, description y location son obligatorios.",
    );
  }

  const companyUid = await resolveActorCompanyUid({
    actorUid: request.auth.uid,
    requestedCompanyUid,
  });

  const salaryValidation = validateSalary(payload);
  const db = getFirestore();
  const companyDoc = await db.collection("companies").doc(companyUid).get();
  const companyData = (companyDoc.data() ?? {}) as JsonRecord;
  const complianceSettings = asJsonRecord(
    companyData.compliance_settings ?? companyData.complianceSettings,
  );
  const companyPrivacyContactEmail = asTrimmedString(
    complianceSettings?.privacy_contact_email ??
      complianceSettings?.privacyContactEmail,
  );
  const companyDpoEmail = asTrimmedString(
    complianceSettings?.dpo_email ?? complianceSettings?.dpoEmail,
  );
  const companyPrivacyPolicyUrl = asTrimmedString(
    complianceSettings?.privacy_policy_url ??
      complianceSettings?.privacyPolicyUrl,
  );
  const companyAiConsentTextVersion =
    asTrimmedString(
      complianceSettings?.ai_consent_text_version ??
        complianceSettings?.aiConsentTextVersion,
    ) || "2026.04";
  const companyAiConsentText =
    asTrimmedString(
      complianceSettings?.ai_consent_text ?? complianceSettings?.aiConsentText,
    ) ||
    "Autorizo el uso de sistemas de IA para test y entrevistas de esta candidatura. " +
      "Entiendo que puedo solicitar revisión humana y revocar en el portal de privacidad.";
  const docRef = db.collection("jobOffers").doc();
  const pipelineId = asNullableString(payload.pipelineId);
  const pipelineStages = pickPipelineArray(payload.pipelineStages);
  const knockoutQuestions = pickPipelineArray(payload.knockoutQuestions);

  const offerData: JsonRecord = {
    id: docRef.id,
    title,
    description,
    location,
    company_uid: companyUid,
    company_id: toFiniteNumber(payload.company_id ?? payload.companyId),
    company_name: asTrimmedString(payload.company_name ?? payload.companyName),
    company_avatar_url: asNullableString(
      payload.company_avatar_url ?? payload.companyAvatarUrl,
    ),
    province_id: asNullableString(payload.province_id ?? payload.provinceId),
    province_name: asNullableString(payload.province_name ?? payload.provinceName),
    municipality_id: asNullableString(
      payload.municipality_id ?? payload.municipalityId,
    ),
    municipality_name: asNullableString(
      payload.municipality_name ?? payload.municipalityName,
    ),
    job_type: asNullableString(payload.job_type ?? payload.jobType),
    education: asNullableString(payload.education),
    job_category: asNullableString(payload.job_category ?? payload.jobCategory),
    work_schedule: asNullableString(
      payload.work_schedule ?? payload.workSchedule,
    ),
    contract_type: asNullableString(
      payload.contract_type ?? payload.contractType,
    ),
    key_indicators: asNullableString(
      payload.key_indicators ?? payload.keyIndicators,
    ),
    language_check_result:
      payload.language_check_result ?? payload.languageCheckResult ?? null,
    company_privacy_contact_email: companyPrivacyContactEmail || null,
    company_dpo_email: companyDpoEmail || null,
    company_privacy_policy_url: companyPrivacyPolicyUrl || null,
    company_ai_consent_text_version: companyAiConsentTextVersion,
    company_ai_consent_text: companyAiConsentText,
    applications_count: 0,
    created_by: request.auth.uid,
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  };
  if (pipelineId !== null) {
    offerData.pipelineId = pipelineId;
  }
  if (pipelineStages !== undefined) {
    offerData.pipelineStages = pipelineStages;
  }
  if (knockoutQuestions !== undefined) {
    offerData.knockoutQuestions = knockoutQuestions;
  }

  if (!salaryValidation.valid) {
    offerData.salary_min = salaryValidation.salaryMin;
    offerData.salary_max = salaryValidation.salaryMax;
    offerData.salary_currency = salaryValidation.salaryCurrency;
    offerData.salary_period = salaryValidation.salaryPeriod;
    offerData.status = "blocked_pending_salary_validation";
    offerData.publication_block_reason = salaryValidation.reasonCode;
    offerData.publication_block_message = salaryValidation.reasonMessage;
    offerData.publication_blocked_at = FieldValue.serverTimestamp();
    offerData.salary_validation = {
      valid: false,
      checkedAt: FieldValue.serverTimestamp(),
      reasonCode: salaryValidation.reasonCode,
      reasonMessage: salaryValidation.reasonMessage,
    };

    await docRef.set(offerData);
    return {
      ok: true,
      offerId: docRef.id,
      status: offerData.status,
      publicationBlocked: true,
      publicationBlockReason: salaryValidation.reasonCode,
      publicationBlockMessage: salaryValidation.reasonMessage,
    };
  }

  offerData.salary_min = salaryValidation.salaryMin;
  offerData.salary_max = salaryValidation.salaryMax;
  offerData.salary_currency = salaryValidation.salaryCurrency;
  offerData.salary_period = salaryValidation.salaryPeriod;
  offerData.status = "active";
  offerData.salary_validation = {
    valid: true,
    checkedAt: FieldValue.serverTimestamp(),
  };

  try {
    validateJobOffer(offerData);
  } catch (error) {
    if (error instanceof ValidationError) {
      throw new HttpsError("invalid-argument", error.message);
    }
    throw error;
  }
  await docRef.set(offerData);

  return {
    ok: true,
    offerId: docRef.id,
    status: "active",
    publicationBlocked: false,
  };
});
