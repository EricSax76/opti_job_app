export type JsonRecord = Record<string, unknown>;

export const VALID_SALARY_PERIODS = new Set(["hour", "day", "week", "month", "year"]);

export function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

export function asNullableString(value: unknown): string | null {
  const normalized = asTrimmedString(value);
  return normalized.length > 0 ? normalized : null;
}

export function toFiniteNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function normalizeSalaryPeriod(value: unknown): string {
  const raw = asTrimmedString(value).toLowerCase();
  if (!raw) return "";
  if (raw === "hourly") return "hour";
  if (raw === "daily") return "day";
  if (raw === "weekly") return "week";
  if (raw === "monthly") return "month";
  if (raw === "annual" || raw === "annually" || raw === "yearly") return "year";
  return raw;
}

export type SalaryValidation =
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

export function validateSalary(payload: JsonRecord): SalaryValidation {
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

/**
 * Validates salary fields on an already-persisted offer document (for publication checks).
 */
export function validateOfferSalaryForPublication(offer: Record<string, unknown>): {
  valid: boolean;
  reasonCode?: string;
  reasonMessage?: string;
} {
  const status = String(offer.status ?? "").trim().toLowerCase();
  if (status === "blocked_pending_salary_validation") {
    return {
      valid: false,
      reasonCode: "blocked_pending_salary_validation",
      reasonMessage: "La oferta está bloqueada por validación salarial.",
    };
  }

  const min = toFiniteNumber(offer.salary_min ?? offer.salaryMin);
  const max = toFiniteNumber(offer.salary_max ?? offer.salaryMax);
  const currency = String(offer.salary_currency ?? offer.salaryCurrency ?? "").trim().toUpperCase();
  const period = normalizeSalaryPeriod(offer.salary_period ?? offer.salaryPeriod);

  if (min == null || max == null || min <= 0 || max <= 0) {
    return { valid: false, reasonCode: "invalid_salary_range", reasonMessage: "La oferta no tiene un rango salarial numérico válido." };
  }
  if (min > max) {
    return { valid: false, reasonCode: "salary_range_inconsistent", reasonMessage: "salary_min no puede ser mayor que salary_max." };
  }
  if (!/^[A-Z]{3}$/.test(currency)) {
    return { valid: false, reasonCode: "invalid_salary_currency", reasonMessage: "La oferta no tiene una moneda salarial válida." };
  }
  if (!VALID_SALARY_PERIODS.has(period)) {
    return { valid: false, reasonCode: "invalid_salary_period", reasonMessage: "La oferta no tiene un periodo salarial válido." };
  }

  return { valid: true };
}
