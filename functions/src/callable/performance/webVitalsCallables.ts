import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

type JsonRecord = Record<string, unknown>;

const VALID_METRICS = new Set(["INP", "LCP", "CLS", "FCP"]);

function asTrimmedString(value: unknown): string {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

function parseNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const raw = asTrimmedString(value);
  if (!raw) return null;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeMetric(value: unknown): string {
  return asTrimmedString(value).toUpperCase();
}

function normalizePath(value: unknown): string {
  const raw = asTrimmedString(value);
  if (!raw) return "/";
  return raw.startsWith("/") ? raw : `/${raw}`;
}

function deriveCompanyId(path: string, explicitCompanyId: string): string | null {
  if (explicitCompanyId) return explicitCompanyId;
  const companyMatch = path.match(/^\/company\/([^/]+)/i);
  if (!companyMatch || companyMatch.length < 2) return null;
  const id = asTrimmedString(companyMatch[1]);
  return id || null;
}

function deriveScope(path: string, companyId: string | null): string {
  if (companyId != null) return "company";
  if (path.startsWith("/candidate/")) return "candidate";
  if (path.startsWith("/job-offer")) return "candidate";
  if (path.startsWith("/Company") || path.startsWith("/company")) return "company";
  return "public";
}

/**
 * Ingests client-side Web Vitals telemetry in batches.
 */
export const reportWebVitalsBatch = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    const events = Array.isArray(data?.events)
      ? (data.events as unknown[]).slice(0, 50)
      : [];

    if (events.length === 0) {
      return { accepted: 0, rejected: 0 };
    }

    const db = admin.firestore();
    let accepted = 0;
    let rejected = 0;

    const writes: Promise<FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>>[] = [];

    for (const rawEvent of events) {
      const event = asRecord(rawEvent);
      const metric = normalizeMetric(event.metric);
      const value = parseNumber(event.value);
      const path = normalizePath(event.path);
      const explicitCompanyId = asTrimmedString(event.companyId);
      const companyId = deriveCompanyId(path, explicitCompanyId);
      const scope = deriveScope(path, companyId);

      if (!VALID_METRICS.has(metric) || value == null || value < 0) {
        rejected += 1;
        continue;
      }

      const rating = asTrimmedString(event.rating).toLowerCase();
      const navType = asTrimmedString(event.navigationType).toLowerCase();
      const pageLoadId = asTrimmedString(event.pageLoadId);

      writes.push(
        db.collection("webVitalsEvents").add({
          metric,
          value,
          rating: rating || "unknown",
          path,
          scope,
          companyId: companyId ?? null,
          userUid: context.auth?.uid ?? null,
          navType: navType || "unknown",
          pageLoadId: pageLoadId || null,
          userAgent: asTrimmedString(event.userAgent) || null,
          source: "web_vitals",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
      );
      accepted += 1;
    }

    if (writes.length > 0) {
      await Promise.all(writes);
    }

    return { accepted, rejected };
  });
