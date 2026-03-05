import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { validateJobOffer } from "../../utils/validation";
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
  const docRef = db.collection("jobOffers").doc();

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
    pipelineId: asNullableString(payload.pipelineId),
    pipelineStages: pickPipelineArray(payload.pipelineStages),
    knockoutQuestions: pickPipelineArray(payload.knockoutQuestions),
    language_check_result:
      payload.language_check_result ?? payload.languageCheckResult ?? null,
    applications_count: 0,
    created_by: request.auth.uid,
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  };

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

  validateJobOffer(offerData);
  await docRef.set(offerData);

  return {
    ok: true,
    offerId: docRef.id,
    status: "active",
    publicationBlocked: false,
  };
});
