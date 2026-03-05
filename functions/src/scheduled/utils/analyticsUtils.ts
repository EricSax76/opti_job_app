import * as admin from "firebase-admin";

export type FirestoreDoc = FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>;
export type JsonDoc = Record<string, unknown>;

export const DEFAULT_CHANNEL_COST_EUR: Record<string, number> = {
  linkedin: 249,
  indeed: 199,
  university_portal: 89,
  infojobs: 149,
  glassdoor: 129,
  github_jobs: 179,
};

export function asRecord(value: unknown): JsonDoc | null {
  if (value == null || typeof value !== "object" || Array.isArray(value)) return null;
  return value as JsonDoc;
}

export function parseDate(value: unknown): Date | null {
  if (value === null || value === undefined) return null;
  if (value instanceof admin.firestore.Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value);
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

export function average(values: number[]): number {
  if (values.length === 0) return 0;
  const sum = values.reduce((acc, current) => acc + current, 0);
  return Number((sum / values.length).toFixed(2));
}

export function toSafeRate(numerator: number, denominator: number): number {
  if (denominator <= 0) return 0;
  return Number((numerator / denominator).toFixed(4));
}

export function pickDate(data: Record<string, unknown>, keys: string[]): Date | null {
  for (const key of keys) {
    const parsed = parseDate(data[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

export function inRange(date: Date | null, start: Date, end: Date): boolean {
  if (date == null) return false;
  return date >= start && date < end;
}

export function dedupeDocs(...snapshots: FirebaseFirestore.QuerySnapshot[]): FirestoreDoc[] {
  const map = new Map<string, FirestoreDoc>();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      map.set(doc.id, doc as FirestoreDoc);
    }
  }
  return [...map.values()];
}

export function normalizeSource(value: unknown): string {
  const normalized = String(value ?? "").trim().toLowerCase();
  return normalized.length > 0 ? normalized : "platform";
}

export function parseNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const normalized = String(value)
    .trim()
    .replace(/[^\d,.\-]/g, "")
    .replace(",", ".");
  if (!normalized) return null;
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : null;
}

export function round2(value: number): number {
  return Number(value.toFixed(2));
}

export function daysBetween(start: Date, end: Date): number {
  const diffMs = end.getTime() - start.getTime();
  return diffMs > 0 ? diffMs / (1000 * 60 * 60 * 24) : 0;
}

export function computePipelineMetrics(applicationsInPeriod: Array<Record<string, unknown>>) {
  const total = applicationsInPeriod.length;
  const status = (app: Record<string, unknown>) => String(app.status ?? "").toLowerCase();

  const interviewOrBeyond = applicationsInPeriod.filter((app) => {
    const s = status(app);
    return s === "interviewing" || s === "offered" || s === "hired";
  }).length;
  const offerOrBeyond = applicationsInPeriod.filter((app) => {
    const s = status(app);
    return s === "offered" || s === "hired";
  }).length;
  const hired = applicationsInPeriod.filter((app) => status(app) === "hired").length;

  return {
    pooled: {
      name: "Pool",
      entered: total,
      advanced: interviewOrBeyond,
      rate: toSafeRate(interviewOrBeyond, total),
    },
    interview: {
      name: "Entrevista",
      entered: interviewOrBeyond,
      advanced: offerOrBeyond,
      rate: toSafeRate(offerOrBeyond, interviewOrBeyond),
    },
    offer: {
      name: "Oferta",
      entered: offerOrBeyond,
      advanced: hired,
      rate: toSafeRate(hired, offerOrBeyond),
    },
  };
}

export function annualizedSalaryValue(offer: JsonDoc | undefined): number {
  if (offer == null) return 30000;
  const salaryMin = parseNumber(offer.salary_min ?? offer.salaryMin);
  const salaryMax = parseNumber(offer.salary_max ?? offer.salaryMax);
  const midpoint =
    salaryMin != null && salaryMax != null
      ? (salaryMin + salaryMax) / 2
      : salaryMin ?? salaryMax;
  if (midpoint == null || midpoint <= 0) return 30000;

  const periodRaw = String(offer.salary_period ?? offer.salaryPeriod ?? "year")
    .trim()
    .toLowerCase();
  const annualized = periodRaw === "month" || periodRaw === "monthly"
    ? midpoint * 12
    : periodRaw === "week" || periodRaw === "weekly"
      ? midpoint * 52
      : periodRaw === "day" || periodRaw === "daily"
        ? midpoint * 220
        : periodRaw === "hour" || periodRaw === "hourly"
          ? midpoint * 1760
          : midpoint;
  return round2(annualized);
}

export function computeSourceEffectiveness({
  applicationsInPeriod,
  hiredApplicationsInPeriod,
  spendBySourceEur,
  hireValueBySourceEur,
}: {
  applicationsInPeriod: JsonDoc[];
  hiredApplicationsInPeriod: JsonDoc[];
  spendBySourceEur: Map<string, number>;
  hireValueBySourceEur: Map<string, number>;
}) {
  const sourceEffectiveness = new Map<
    string,
    { applications: number; hires: number; spendEur: number; attributedHireValueEur: number }
  >();

  for (const app of applicationsInPeriod) {
    const source = normalizeSource(app.source_channel ?? app.sourceChannel ?? app.source);
    const bucket = sourceEffectiveness.get(source) ?? {
      applications: 0,
      hires: 0,
      spendEur: 0,
      attributedHireValueEur: 0,
    };
    bucket.applications += 1;
    sourceEffectiveness.set(source, bucket);
  }

  for (const app of hiredApplicationsInPeriod) {
    const source = normalizeSource(app.source_channel ?? app.sourceChannel ?? app.source);
    const bucket = sourceEffectiveness.get(source) ?? {
      applications: 0,
      hires: 0,
      spendEur: 0,
      attributedHireValueEur: 0,
    };
    bucket.hires += 1;
    sourceEffectiveness.set(source, bucket);
  }

  for (const [source, spend] of spendBySourceEur.entries()) {
    const bucket = sourceEffectiveness.get(source) ?? {
      applications: 0,
      hires: 0,
      spendEur: 0,
      attributedHireValueEur: 0,
    };
    bucket.spendEur = round2(spend);
    sourceEffectiveness.set(source, bucket);
  }

  for (const [source, value] of hireValueBySourceEur.entries()) {
    const bucket = sourceEffectiveness.get(source) ?? {
      applications: 0,
      hires: 0,
      spendEur: 0,
      attributedHireValueEur: 0,
    };
    bucket.attributedHireValueEur = round2(value);
    sourceEffectiveness.set(source, bucket);
  }

  return Object.fromEntries(
    [...sourceEffectiveness.entries()].map(([source, metrics]) => {
      const spend = metrics.spendEur;
      const attributed = metrics.attributedHireValueEur;
      const costPerApplication = metrics.applications > 0
        ? round2(spend / metrics.applications)
        : 0;
      const costPerHire = metrics.hires > 0 ? round2(spend / metrics.hires) : 0;
      const roi = spend > 0 ? round2((attributed - spend) / spend) : 0;
      return [
        source,
        {
          applications: metrics.applications,
          hires: metrics.hires,
          spendEur: spend,
          attributedHireValueEur: attributed,
          conversionRate: toSafeRate(metrics.hires, metrics.applications),
          costPerApplicationEur: costPerApplication,
          costPerHireEur: costPerHire,
          roi,
        },
      ];
    }),
  );
}

export function computeRecruiterMetrics(
  evaluationsInPeriod: Array<Record<string, unknown>>,
  applicationsById: Map<string, Record<string, unknown>>,
) {
  const byRecruiter = new Map<
    string,
    { name: string; evaluations: number; responseDays: number[] }
  >();

  for (const evaluation of evaluationsInPeriod) {
    const evaluatorUid = String(evaluation.evaluatorUid ?? "").trim();
    if (evaluatorUid.length === 0) continue;
    const evaluatorName = String(evaluation.evaluatorName ?? "").trim() || evaluatorUid;
    const bucket = byRecruiter.get(evaluatorUid) ?? {
      name: evaluatorName,
      evaluations: 0,
      responseDays: [],
    };
    bucket.evaluations += 1;

    const evaluationCreatedAt = parseDate(evaluation.createdAt);
    const applicationId = String(evaluation.applicationId ?? "").trim();
    const app = applicationId.length > 0 ? applicationsById.get(applicationId) : null;
    const submittedAt = app
      ? pickDate(app, ["submitted_at", "submittedAt", "created_at", "createdAt"])
      : null;
    if (submittedAt != null && evaluationCreatedAt != null) {
      bucket.responseDays.push(daysBetween(submittedAt, evaluationCreatedAt));
    }
    byRecruiter.set(evaluatorUid, bucket);
  }

  const finalMetrics = Object.fromEntries(
    [...byRecruiter.entries()].map(([uid, row]) => [
      uid,
      {
        name: row.name,
        evaluations: row.evaluations,
        avgResponseTime: average(row.responseDays),
      },
    ]),
  );
  return finalMetrics;
}

export function monthBounds(date: Date): { start: Date; end: Date; period: string } {
  const start = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1, 0, 0, 0));
  const end = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1, 0, 0, 0));
  const period = `${start.getUTCFullYear()}-${String(start.getUTCMonth() + 1).padStart(2, "0")}`;
  return { start, end, period };
}
