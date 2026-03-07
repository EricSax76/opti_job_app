import * as admin from "firebase-admin";
import { asTrimmedString } from "./complianceUtils";

export type ComplianceOperation = "processDataRequest" | "exportCandidateData";
export type ComplianceOutcome = "success" | "error";

export interface RecordComplianceOperationInput {
  db?: FirebaseFirestore.Firestore;
  operation: ComplianceOperation;
  outcome: ComplianceOutcome;
  actorUid: string;
  candidateUid?: string | null;
  companyId?: string | null;
  requestId?: string | null;
  latencyMs: number;
  errorCode?: string | null;
  metadata?: Record<string, unknown>;
  resolvedWithinSla?: boolean | null;
  slaBreached?: boolean;
}

function clampLatencyMs(value: number): number {
  if (!Number.isFinite(value)) return 0;
  const rounded = Math.round(value);
  return rounded < 0 ? 0 : rounded;
}

function utcDateKey(now: Date): string {
  return now.toISOString().slice(0, 10);
}

function dailyDocId(scopeId: string, dateKey: string): string {
  return `${scopeId}:${dateKey}`.replace(/\//g, "_");
}

export async function recordComplianceOperation({
  db,
  operation,
  outcome,
  actorUid,
  candidateUid,
  companyId,
  requestId,
  latencyMs,
  errorCode,
  metadata = {},
  resolvedWithinSla,
  slaBreached = false,
}: RecordComplianceOperationInput): Promise<void> {
  const firestore = db ?? admin.firestore();
  const nowDate = new Date();
  const nowTs = admin.firestore.Timestamp.fromDate(nowDate);
  const dateKey = utcDateKey(nowDate);
  const normalizedCompanyId = asTrimmedString(companyId) || null;
  const scopeId = normalizedCompanyId ?? "global";
  const safeLatencyMs = clampLatencyMs(latencyMs);
  const normalizedErrorCode = asTrimmedString(errorCode) || null;
  const normalizedRequestId = asTrimmedString(requestId) || null;
  const normalizedCandidateUid = asTrimmedString(candidateUid) || null;

  await firestore.collection("complianceOpsEvents").add({
    operation,
    outcome,
    actorUid,
    candidateUid: normalizedCandidateUid,
    companyId: normalizedCompanyId,
    requestId: normalizedRequestId,
    latencyMs: safeLatencyMs,
    errorCode: normalizedErrorCode,
    resolvedWithinSla: resolvedWithinSla ?? null,
    slaBreached: Boolean(slaBreached),
    dateKey,
    metadata,
    timestamp: nowTs,
  });

  const summaryRef = firestore
    .collection("complianceOpsDaily")
    .doc(dailyDocId(scopeId, dateKey));

  await summaryRef.set(
    {
      scopeId,
      companyId: normalizedCompanyId,
      dateKey,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const summaryUpdate: Record<string, unknown> = {
    [`operations.${operation}.invocations`]:
      admin.firestore.FieldValue.increment(1),
    [`operations.${operation}.successCount`]:
      admin.firestore.FieldValue.increment(outcome === "success" ? 1 : 0),
    [`operations.${operation}.errorCount`]:
      admin.firestore.FieldValue.increment(outcome === "error" ? 1 : 0),
    [`operations.${operation}.totalLatencyMs`]:
      admin.firestore.FieldValue.increment(safeLatencyMs),
    [`operations.${operation}.lastLatencyMs`]: safeLatencyMs,
    [`operations.${operation}.lastInvocationAt`]: nowTs,
    "alerts.errorCount": admin.firestore.FieldValue.increment(
      outcome === "error" ? 1 : 0
    ),
  };

  if (outcome === "error") {
    summaryUpdate[`operations.${operation}.lastErrorAt`] = nowTs;
    summaryUpdate[`operations.${operation}.lastErrorCode`] = normalizedErrorCode;
    summaryUpdate["alerts.hasErrors"] = true;
    summaryUpdate["alerts.lastErrorAt"] = nowTs;
    summaryUpdate["alerts.lastErrorCode"] = normalizedErrorCode;
  }

  if (resolvedWithinSla !== undefined && resolvedWithinSla !== null) {
    summaryUpdate["sla.completedCount"] = admin.firestore.FieldValue.increment(1);
    summaryUpdate["sla.lastResolvedAt"] = nowTs;
    summaryUpdate["sla.completedWithinCount"] = admin.firestore.FieldValue.increment(
      resolvedWithinSla ? 1 : 0
    );
    summaryUpdate["sla.completedOutsideCount"] = admin.firestore.FieldValue.increment(
      resolvedWithinSla ? 0 : 1
    );
  }

  if (slaBreached) {
    summaryUpdate["alerts.hasSlaBreaches"] = true;
    summaryUpdate["alerts.slaBreachCount"] =
      admin.firestore.FieldValue.increment(1);
    summaryUpdate["alerts.lastSlaBreachAt"] = nowTs;
  }

  await summaryRef.update(summaryUpdate);
}
