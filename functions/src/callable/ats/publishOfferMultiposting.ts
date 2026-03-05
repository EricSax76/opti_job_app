import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const CHANNEL_CATALOG = {
  linkedin: { label: "LinkedIn", defaultCostEur: 249 },
  indeed: { label: "Indeed", defaultCostEur: 199 },
  university_portal: { label: "Portal universitario", defaultCostEur: 89 },
  infojobs: { label: "InfoJobs", defaultCostEur: 149 },
  glassdoor: { label: "Glassdoor", defaultCostEur: 129 },
  github_jobs: { label: "GitHub Jobs", defaultCostEur: 179 },
} as const;

const DEFAULT_CHANNELS: readonly SupportedChannel[] = [
  "linkedin",
  "indeed",
  "university_portal",
];
const VALID_SALARY_PERIODS = new Set(["hour", "day", "week", "month", "year"]);

type SupportedChannel = keyof typeof CHANNEL_CATALOG;

interface NormalizedChannelRequest {
  channel: SupportedChannel;
  costOverrideEur: number | null;
}

interface CompanyChannelSettings {
  enabledChannels: SupportedChannel[];
  costOverridesEur: Partial<Record<SupportedChannel, number>>;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function asNonNegativeNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value) && value >= 0) return value;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) return null;
  return parsed;
}

function normalizeChannel(value: unknown): SupportedChannel | null {
  const raw = String(value ?? "").trim().toLowerCase();
  if (raw === "linkedin") return "linkedin";
  if (raw === "indeed") return "indeed";
  if (raw === "university_portal" || raw === "university" || raw === "universities") {
    return "university_portal";
  }
  if (raw === "infojobs") return "infojobs";
  if (raw === "glassdoor") return "glassdoor";
  if (raw === "github_jobs" || raw === "github-jobs" || raw === "github") {
    return "github_jobs";
  }
  return null;
}

function normalizeChannelRequest(value: unknown): NormalizedChannelRequest | null {
  if (typeof value === "string") {
    const channel = normalizeChannel(value);
    return channel ? { channel, costOverrideEur: null } : null;
  }
  const row = asRecord(value);
  if (row == null) return null;

  const channel = normalizeChannel(row.channel ?? row.id ?? row.name);
  if (channel == null) return null;

  const costOverrideEur = asNonNegativeNumber(
    row.costEur ?? row.cost ?? row.estimatedCost,
  );
  return { channel, costOverrideEur };
}

function normalizeRequestedChannels(raw: unknown): NormalizedChannelRequest[] {
  if (!Array.isArray(raw) || raw.length === 0) return [];
  const deduped = new Map<SupportedChannel, NormalizedChannelRequest>();
  for (const item of raw) {
    const normalized = normalizeChannelRequest(item);
    if (normalized == null) continue;
    deduped.set(normalized.channel, normalized);
  }
  return [...deduped.values()];
}

function pickNonEmptyString(...values: unknown[]): string {
  for (const value of values) {
    const normalized = String(value ?? "").trim();
    if (normalized.length > 0) return normalized;
  }
  return "";
}

async function assertCanManageOffer(
  db: FirebaseFirestore.Firestore,
  actorUid: string,
  companyId: string,
): Promise<void> {
  if (actorUid === companyId) return;
  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Only company users or recruiters with publishing permissions can multipost.",
    );
  }
  const recruiter = recruiterDoc.data() as Record<string, unknown>;
  const recruiterCompanyId = String(recruiter.companyId ?? "").trim();
  const recruiterStatus = String(recruiter.status ?? "").trim();
  const recruiterRole = String(recruiter.role ?? "").trim();
  const canManageOffers = recruiterRole === "admin" || recruiterRole === "recruiter";
  if (recruiterCompanyId !== companyId || recruiterStatus !== "active" || !canManageOffers) {
    throw new HttpsError(
      "permission-denied",
      "Your role cannot publish this offer to external channels.",
    );
  }
}

function buildTrackingUrl(offerId: string, channel: SupportedChannel): string {
  const base = process.env.PUBLIC_JOB_BASE_URL?.trim() || "https://optimizzate-eb14a.web.app";
  return `${base}/job-offer/${offerId}?source=${channel}&utm_source=${channel}&utm_medium=multiposting`;
}

function defaultCompanyChannelSettings(): CompanyChannelSettings {
  return {
    enabledChannels: [...DEFAULT_CHANNELS],
    costOverridesEur: {},
  };
}

async function getCompanyChannelSettings(
  db: FirebaseFirestore.Firestore,
  companyId: string,
): Promise<CompanyChannelSettings> {
  const companyDoc = await db.collection("companies").doc(companyId).get();
  if (!companyDoc.exists) return defaultCompanyChannelSettings();

  const company = companyDoc.data() as Record<string, unknown>;
  const rawSettings =
    asRecord(company.multipostingChannelSettings) ??
    asRecord(company.multiposting_channel_settings);
  if (rawSettings == null) return defaultCompanyChannelSettings();

  const enabledByCompany = Array.isArray(rawSettings.enabledChannels)
    ? rawSettings.enabledChannels
        .map(normalizeChannel)
        .filter((value): value is SupportedChannel => value != null)
    : [];

  const channelMap = asRecord(rawSettings.channels);
  const costOverridesEur: Partial<Record<SupportedChannel, number>> = {};
  const enabledFromMap: SupportedChannel[] = [];
  if (channelMap != null) {
    for (const [rawKey, rawValue] of Object.entries(channelMap)) {
      const channel = normalizeChannel(rawKey);
      if (channel == null) continue;
      const row = asRecord(rawValue) ?? {};
      const enabled = row.enabled !== false;
      if (enabled) enabledFromMap.push(channel);
      const override = asNonNegativeNumber(row.costEur ?? row.cost);
      if (override != null) {
        costOverridesEur[channel] = override;
      }
    }
  }

  const enabledChannels = Array.from(
    new Set(
      [...enabledByCompany, ...enabledFromMap].filter((value) => value != null),
    ),
  );
  return {
    enabledChannels: enabledChannels.length > 0 ? enabledChannels : [...DEFAULT_CHANNELS],
    costOverridesEur,
  };
}

function resolveChannelsToPublish(
  requested: NormalizedChannelRequest[],
  companySettings: CompanyChannelSettings,
): NormalizedChannelRequest[] {
  if (requested.length > 0) return requested;
  return companySettings.enabledChannels.map((channel) => ({
    channel,
    costOverrideEur: null,
  }));
}

function resolveChannelCostEur(
  channel: SupportedChannel,
  requestOverrideEur: number | null,
  companySettings: CompanyChannelSettings,
): number {
  if (requestOverrideEur != null) return requestOverrideEur;
  const companyOverride = companySettings.costOverridesEur[channel];
  if (companyOverride != null) return companyOverride;
  return CHANNEL_CATALOG[channel].defaultCostEur;
}

function toFiniteNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeSalaryPeriod(value: unknown): string {
  const raw = String(value ?? "").trim().toLowerCase();
  if (!raw) return "";
  if (raw === "hourly") return "hour";
  if (raw === "daily") return "day";
  if (raw === "weekly") return "week";
  if (raw === "monthly") return "month";
  if (raw === "annual" || raw === "annually" || raw === "yearly") return "year";
  return raw;
}

function validateOfferSalaryForPublication(offer: Record<string, unknown>): {
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
  const currency = String(
    offer.salary_currency ?? offer.salaryCurrency ?? "",
  ).trim().toUpperCase();
  const period = normalizeSalaryPeriod(offer.salary_period ?? offer.salaryPeriod);

  if (min == null || max == null || min <= 0 || max <= 0) {
    return {
      valid: false,
      reasonCode: "invalid_salary_range",
      reasonMessage: "La oferta no tiene un rango salarial numérico válido.",
    };
  }
  if (min > max) {
    return {
      valid: false,
      reasonCode: "salary_range_inconsistent",
      reasonMessage: "salary_min no puede ser mayor que salary_max.",
    };
  }
  if (!/^[A-Z]{3}$/.test(currency)) {
    return {
      valid: false,
      reasonCode: "invalid_salary_currency",
      reasonMessage: "La oferta no tiene una moneda salarial válida.",
    };
  }
  if (!VALID_SALARY_PERIODS.has(period)) {
    return {
      valid: false,
      reasonCode: "invalid_salary_period",
      reasonMessage: "La oferta no tiene un periodo salarial válido.",
    };
  }

  return { valid: true };
}

export const publishOfferMultiposting = onCall({ region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const offerId = pickNonEmptyString(request.data?.jobOfferId, request.data?.offerId);
  if (!offerId) {
    throw new HttpsError("invalid-argument", "jobOfferId es obligatorio.");
  }

  const db = getFirestore();
  const actorUid = request.auth.uid;
  const offerRef = db.collection("jobOffers").doc(offerId);
  const offerDoc = await offerRef.get();
  if (!offerDoc.exists) {
    throw new HttpsError("not-found", "Oferta no encontrada.");
  }

  const offer = offerDoc.data() as Record<string, unknown>;
  const companyId = pickNonEmptyString(offer.company_uid, offer.companyUid, offer.owner_uid);
  if (!companyId) {
    throw new HttpsError(
      "failed-precondition",
      "La oferta no contiene empresa propietaria.",
    );
  }

  await assertCanManageOffer(db, actorUid, companyId);

  const salaryValidation = validateOfferSalaryForPublication(offer);
  if (!salaryValidation.valid) {
    await offerRef.set(
      {
        status: "blocked_pending_salary_validation",
        publication_block_reason:
          salaryValidation.reasonCode ?? "invalid_salary_range",
        publication_block_message:
          salaryValidation.reasonMessage ??
          "La oferta no cumple validaciones salariales obligatorias.",
        publication_blocked_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    throw new HttpsError(
      "failed-precondition",
      salaryValidation.reasonMessage ??
        "No se puede publicar sin rango salarial válido.",
    );
  }

  const companySettings = await getCompanyChannelSettings(db, companyId);
  const requestedChannels = normalizeRequestedChannels(request.data?.channels);
  const channels = resolveChannelsToPublish(requestedChannels, companySettings);
  if (channels.length === 0) {
    throw new HttpsError("failed-precondition", "No hay canales habilitados para multiposting.");
  }

  const now = FieldValue.serverTimestamp();
  const publishBatchId = Date.now().toString(36);
  const publications = channels.map((selection) => {
    const channel = selection.channel;
    const channelMeta = CHANNEL_CATALOG[channel];
    const costEur = resolveChannelCostEur(
      channel,
      selection.costOverrideEur,
      companySettings,
    );
    const trackingUrl = buildTrackingUrl(offerId, channel);
    return {
      channel,
      channelLabel: channelMeta.label,
      trackingUrl,
      publicationId: `${offerId}_${channel}_${publishBatchId}`,
      externalPostId: `mvp_${channel}_${offerId}_${publishBatchId}`,
      costEur,
    };
  });

  const batch = db.batch();
  for (const publication of publications) {
    const ref = db.collection("multipostingPublications").doc(publication.publicationId);
    batch.set(
      ref,
      {
        id: publication.publicationId,
        offerId,
        companyId,
        channel: publication.channel,
        channelLabel: publication.channelLabel,
        status: "published",
        trackingUrl: publication.trackingUrl,
        externalPostId: publication.externalPostId,
        attributionKey: publication.channel,
        cost: {
          amount: publication.costEur,
          currency: "EUR",
          model: "flat_posting",
        },
        publishedBy: actorUid,
        publishedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
  }

  const offerUpdates: Record<string, unknown> = {
    multiposting_enabled_channels: publications.map((row) => row.channel),
    multiposting_updated_at: now,
    updated_at: now,
  };
  for (const publication of publications) {
    offerUpdates[`multiposting.channels.${publication.channel}`] = {
      status: "published",
      channelLabel: publication.channelLabel,
      trackingUrl: publication.trackingUrl,
      externalPostId: publication.externalPostId,
      attributionKey: publication.channel,
      cost: {
        amount: publication.costEur,
        currency: "EUR",
        model: "flat_posting",
      },
      publishedBy: actorUid,
      publishedAt: now,
    };
  }
  batch.set(offerRef, offerUpdates, { merge: true });

  await batch.commit();

  const totalEstimatedCostEur = publications.reduce(
    (acc, publication) => acc + publication.costEur,
    0,
  );
  return {
    ok: true,
    offerId,
    companyId,
    channels: publications.map((row) => ({
      channel: row.channel,
      channelLabel: row.channelLabel,
      trackingUrl: row.trackingUrl,
      status: "published",
      estimatedCostEur: row.costEur,
    })),
    totalEstimatedCostEur: Number(totalEstimatedCostEur.toFixed(2)),
  };
});
