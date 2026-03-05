import { getFirestore } from "firebase-admin/firestore";

export const CHANNEL_CATALOG = {
  linkedin: { label: "LinkedIn", defaultCostEur: 249 },
  indeed: { label: "Indeed", defaultCostEur: 199 },
  university_portal: { label: "Portal universitario", defaultCostEur: 89 },
  infojobs: { label: "InfoJobs", defaultCostEur: 149 },
  glassdoor: { label: "Glassdoor", defaultCostEur: 129 },
  github_jobs: { label: "GitHub Jobs", defaultCostEur: 179 },
} as const;

export const DEFAULT_CHANNELS: readonly SupportedChannel[] = [
  "linkedin",
  "indeed",
  "university_portal",
];

export type SupportedChannel = keyof typeof CHANNEL_CATALOG;

export interface NormalizedChannelRequest {
  channel: SupportedChannel;
  costOverrideEur: number | null;
}

export interface CompanyChannelSettings {
  enabledChannels: SupportedChannel[];
  costOverridesEur: Partial<Record<SupportedChannel, number>>;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value == null || typeof value !== "object" || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function asNonNegativeNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value) && value >= 0) return value;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < 0) return null;
  return parsed;
}

export function normalizeChannel(value: unknown): SupportedChannel | null {
  const raw = String(value ?? "").trim().toLowerCase();
  if (raw === "linkedin") return "linkedin";
  if (raw === "indeed") return "indeed";
  if (raw === "university_portal" || raw === "university" || raw === "universities") return "university_portal";
  if (raw === "infojobs") return "infojobs";
  if (raw === "glassdoor") return "glassdoor";
  if (raw === "github_jobs" || raw === "github-jobs" || raw === "github") return "github_jobs";
  return null;
}

export function normalizeChannelRequest(value: unknown): NormalizedChannelRequest | null {
  if (typeof value === "string") {
    const channel = normalizeChannel(value);
    return channel ? { channel, costOverrideEur: null } : null;
  }
  const row = asRecord(value);
  if (row == null) return null;
  const channel = normalizeChannel(row.channel ?? row.id ?? row.name);
  if (channel == null) return null;
  const costOverrideEur = asNonNegativeNumber(row.costEur ?? row.cost ?? row.estimatedCost);
  return { channel, costOverrideEur };
}

export function normalizeRequestedChannels(raw: unknown): NormalizedChannelRequest[] {
  if (!Array.isArray(raw) || raw.length === 0) return [];
  const deduped = new Map<SupportedChannel, NormalizedChannelRequest>();
  for (const item of raw) {
    const normalized = normalizeChannelRequest(item);
    if (normalized == null) continue;
    deduped.set(normalized.channel, normalized);
  }
  return [...deduped.values()];
}

export function resolveChannelsToPublish(
  requested: NormalizedChannelRequest[],
  companySettings: CompanyChannelSettings,
): NormalizedChannelRequest[] {
  if (requested.length > 0) return requested;
  return companySettings.enabledChannels.map((channel) => ({ channel, costOverrideEur: null }));
}

export function resolveChannelCostEur(
  channel: SupportedChannel,
  requestOverrideEur: number | null,
  companySettings: CompanyChannelSettings,
): number {
  if (requestOverrideEur != null) return requestOverrideEur;
  const companyOverride = companySettings.costOverridesEur[channel];
  if (companyOverride != null) return companyOverride;
  return CHANNEL_CATALOG[channel].defaultCostEur;
}

export function buildTrackingUrl(offerId: string, channel: SupportedChannel): string {
  const base = process.env.PUBLIC_JOB_BASE_URL?.trim() || "https://optimizzate-eb14a.web.app";
  return `${base}/job-offer/${offerId}?source=${channel}&utm_source=${channel}&utm_medium=multiposting`;
}

function defaultCompanyChannelSettings(): CompanyChannelSettings {
  return { enabledChannels: [...DEFAULT_CHANNELS], costOverridesEur: {} };
}

export async function getCompanyChannelSettings(companyId: string): Promise<CompanyChannelSettings> {
  const db = getFirestore();
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
      const override = asNonNegativeNumber((row as Record<string, unknown>).costEur ?? (row as Record<string, unknown>).cost);
      if (override != null) costOverridesEur[channel] = override;
    }
  }

  const enabledChannels = Array.from(
    new Set([...enabledByCompany, ...enabledFromMap].filter((value) => value != null)),
  );
  return {
    enabledChannels: enabledChannels.length > 0 ? enabledChannels : [...DEFAULT_CHANNELS],
    costOverridesEur,
  };
}
