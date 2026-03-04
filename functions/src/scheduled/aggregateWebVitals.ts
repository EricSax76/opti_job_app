import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const INP_ALERT_THRESHOLD_MS = 200;
const LOOKBACK_HOURS = 24;
const MAX_EVENTS = 5000;

function percentile(sortedValues: number[], percentileValue: number): number {
  if (sortedValues.length === 0) return 0;
  if (sortedValues.length === 1) return Number(sortedValues[0].toFixed(2));

  const index = (percentileValue / 100) * (sortedValues.length - 1);
  const lower = Math.floor(index);
  const upper = Math.ceil(index);
  if (lower === upper) return Number(sortedValues[lower].toFixed(2));

  const weight = index - lower;
  const value = sortedValues[lower] * (1 - weight) + sortedValues[upper] * weight;
  return Number(value.toFixed(2));
}

function ratingForInp(value: number): "good" | "needs_improvement" | "poor" {
  if (value <= 200) return "good";
  if (value <= 500) return "needs_improvement";
  return "poor";
}

interface MetricAccumulator {
  values: number[];
  count: number;
}

interface DashboardAccumulator {
  scope: string;
  companyId: string | null;
  metrics: Map<string, MetricAccumulator>;
}

function ensureMetricBucket(
  accumulator: DashboardAccumulator,
  metric: string,
): MetricAccumulator {
  const existing = accumulator.metrics.get(metric);
  if (existing != null) return existing;
  const created: MetricAccumulator = { values: [], count: 0 };
  accumulator.metrics.set(metric, created);
  return created;
}

export const aggregateWebVitalsP75 = functions.pubsub
  .schedule("every 30 minutes")
  .onRun(async () => {
    const db = admin.firestore();
    const sinceMillis = Date.now() - LOOKBACK_HOURS * 60 * 60 * 1000;
    const since = admin.firestore.Timestamp.fromMillis(sinceMillis);

    const snapshot = await db
      .collection("webVitalsEvents")
      .where("timestamp", ">=", since)
      .limit(MAX_EVENTS)
      .get();

    const byKey = new Map<string, DashboardAccumulator>();

    for (const doc of snapshot.docs) {
      const data = doc.data() as Record<string, unknown>;
      const metric = String(data.metric ?? "").toUpperCase();
      const rawValue = data.value;
      const value = typeof rawValue === "number" ? rawValue : Number(rawValue);
      if (!metric || !Number.isFinite(value) || value < 0) continue;

      const scope = String(data.scope ?? "public").trim() || "public";
      const companyIdRaw = String(data.companyId ?? "").trim();
      const companyId = companyIdRaw || null;
      const key = companyId != null ? `company:${companyId}` : `scope:${scope}`;

      const accumulator = byKey.get(key) ?? {
        scope,
        companyId,
        metrics: new Map<string, MetricAccumulator>(),
      };

      const bucket = ensureMetricBucket(accumulator, metric);
      bucket.values.push(value);
      bucket.count += 1;

      byKey.set(key, accumulator);
    }

    const writes: Promise<FirebaseFirestore.WriteResult>[] = [];

    for (const [key, accumulator] of byKey.entries()) {
      const metricsPayload: Record<string, unknown> = {};

      for (const [metric, bucket] of accumulator.metrics.entries()) {
        if (bucket.values.length === 0) continue;
        bucket.values.sort((a, b) => a - b);

        const p75 = percentile(bucket.values, 75);
        const p95 = percentile(bucket.values, 95);
        const avg = Number(
          (
            bucket.values.reduce((acc, current) => acc + current, 0) /
            bucket.values.length
          ).toFixed(2),
        );

        metricsPayload[metric] = {
          samples: bucket.count,
          p75,
          p95,
          avg,
          rating: metric === "INP" ? ratingForInp(p75) : "n/a",
        };
      }

      const inpMetric = metricsPayload.INP as
        | { p75?: number; samples?: number }
        | undefined;
      const inpP75 = inpMetric?.p75 ?? 0;
      const inpSamples = inpMetric?.samples ?? 0;
      const degraded = inpSamples >= 20 && inpP75 > INP_ALERT_THRESHOLD_MS;

      const dashboardDocId = key.replace(/[^a-zA-Z0-9:_-]/g, "_");
      writes.push(
        db.collection("performanceDashboards").doc(dashboardDocId).set(
          {
            key,
            scope: accumulator.scope,
            companyId: accumulator.companyId,
            lookbackHours: LOOKBACK_HOURS,
            metrics: metricsPayload,
            alerts: {
              inpDegraded: degraded,
              thresholdMs: INP_ALERT_THRESHOLD_MS,
              reason: degraded
                ? `INP p75 ${inpP75}ms por encima de ${INP_ALERT_THRESHOLD_MS}ms`
                : null,
            },
            sampleCount: snapshot.size,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        ),
      );
    }

    if (writes.length > 0) {
      await Promise.all(writes);
    }

    console.log(
      `Web vitals aggregation completed: docs=${writes.length} events=${snapshot.size}`,
    );
    return null;
  });
