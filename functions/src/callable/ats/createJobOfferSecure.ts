import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { validateJobOffer } from "../../utils/validation";

type JsonRecord = Record<string, unknown>;

const VALID_SALARY_PERIODS = new Set([
  "hour",
  "day",
  "week",
  "month",
  "year",
]);

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function asNullableString(value: unknown): string | null {
  const normalized = asTrimmedString(value);
  return normalized.length > 0 ? normalized : null;
}

function toFiniteNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeSalaryPeriod(value: unknown): string {
  const raw = asTrimmedString(value).toLowerCase();
  if (!raw) return "";
  if (raw === "hourly") return "hour";
  if (raw === "daily") return "day";
  if (raw === "weekly") return "week";
  if (raw === "monthly") return "month";
  if (raw === "annual" || raw === "annually" || raw === "yearly") return "year";
  return raw;
}

type SalaryValidation =
  | {
      valid: true;
      salaryMin: string;
      salaryMax: string;
      salaryCurrency: string;
      salaryPeriod: string;
    }
  | {
      valid: false;
      reasonCode: string;
      reasonMessage: string;
      salaryMin: string;
      salaryMax: string;
      salaryCurrency: string;
      salaryPeriod: string;
    };

function validateSalary(payload: JsonRecord): SalaryValidation {
  const salaryMinRaw = asTrimmedString(payload.salary_min ?? payload.salaryMin);
  const salaryMaxRaw = asTrimmedString(payload.salary_max ?? payload.salaryMax);
  const salaryCurrency = asTrimmedString(
    payload.salary_currency ?? payload.salaryCurrency,
  ).toUpperCase();
  const salaryPeriod = normalizeSalaryPeriod(
    payload.salary_period ?? payload.salaryPeriod,
  );

  const min = toFiniteNumber(salaryMinRaw);
  const max = toFiniteNumber(salaryMaxRaw);

  if (min == null || max == null) {
    return {
      valid: false,
      reasonCode: "missing_salary_range",
      reasonMessage: "salary_min y salary_max son obligatorios y deben ser numéricos.",
      salaryMin: salaryMinRaw,
      salaryMax: salaryMaxRaw,
      salaryCurrency,
      salaryPeriod,
    };
  }

  if (min <= 0 || max <= 0) {
    return {
      valid: false,
      reasonCode: "invalid_salary_range_values",
      reasonMessage: "salary_min y salary_max deben ser mayores que cero.",
      salaryMin: salaryMinRaw,
      salaryMax: salaryMaxRaw,
      salaryCurrency,
      salaryPeriod,
    };
  }

  if (min > max) {
    return {
      valid: false,
      reasonCode: "salary_range_inconsistent",
      reasonMessage: "salary_min no puede ser mayor que salary_max.",
      salaryMin: String(min),
      salaryMax: String(max),
      salaryCurrency,
      salaryPeriod,
    };
  }

  if (!/^[A-Z]{3}$/.test(salaryCurrency)) {
    return {
      valid: false,
      reasonCode: "invalid_salary_currency",
      reasonMessage: "salary_currency debe estar en formato ISO-4217 (p.ej. EUR).",
      salaryMin: String(min),
      salaryMax: String(max),
      salaryCurrency,
      salaryPeriod,
    };
  }

  if (!VALID_SALARY_PERIODS.has(salaryPeriod)) {
    return {
      valid: false,
      reasonCode: "invalid_salary_period",
      reasonMessage: "salary_period debe ser hour, day, week, month o year.",
      salaryMin: String(min),
      salaryMax: String(max),
      salaryCurrency,
      salaryPeriod,
    };
  }

  return {
    valid: true,
    salaryMin: String(min),
    salaryMax: String(max),
    salaryCurrency,
    salaryPeriod,
  };
}

async function resolveActorCompanyUid({
  actorUid,
  requestedCompanyUid,
}: {
  actorUid: string;
  requestedCompanyUid: string;
}): Promise<string> {
  const db = getFirestore();
  const actorCompanyDoc = await db.collection("companies").doc(actorUid).get();

  if (actorCompanyDoc.exists && !requestedCompanyUid) {
    return actorUid;
  }
  if (requestedCompanyUid && requestedCompanyUid === actorUid) {
    return actorUid;
  }

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Solo la empresa propietaria o un recruiter autorizado puede crear ofertas.",
    );
  }

  const recruiter = recruiterDoc.data() as JsonRecord;
  const role = asTrimmedString(recruiter.role).toLowerCase();
  const status = asTrimmedString(recruiter.status).toLowerCase();
  const recruiterCompanyId = asTrimmedString(recruiter.companyId);
  if (!recruiterCompanyId || status !== "active") {
    throw new HttpsError(
      "permission-denied",
      "El recruiter no está activo o no tiene empresa asociada.",
    );
  }
  if (!["admin", "recruiter"].includes(role)) {
    throw new HttpsError(
      "permission-denied",
      "Tu rol de recruiter no tiene permisos para crear ofertas.",
    );
  }
  if (requestedCompanyUid && requestedCompanyUid !== recruiterCompanyId) {
    throw new HttpsError(
      "permission-denied",
      "No puedes crear ofertas para otra empresa.",
    );
  }
  return recruiterCompanyId;
}

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
