import * as admin from "firebase-admin";

export async function logAuditEntry({
  action,
  actorUid,
  actorRole,
  targetType,
  targetId,
  companyId,
  metadata = {},
}: {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  companyId?: string | null;
  metadata?: Record<string, unknown>;
}): Promise<void> {
  await admin.firestore().collection("auditLogs").add({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: companyId ?? null,
    metadata,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}
