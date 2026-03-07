import { writeAuditLog } from "../../../utils/auditLog";

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
  await writeAuditLog({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: companyId ?? null,
    metadata,
  });
}
