import { JsonRecord } from "./eudiUtils";
import { writeAuditLog } from "../../../utils/auditLog";

export async function logAuditEntry({
  action,
  actorUid,
  actorRole,
  targetType,
  targetId,
  companyId,
  metadata,
  verificationMethod,
  issuerDid,
  credentialType,
  proofSchemaVersion,
}: {
  action: string;
  actorUid: string;
  actorRole: string;
  targetType: string;
  targetId: string;
  companyId?: string | null;
  metadata: JsonRecord;
  verificationMethod?: string | null;
  issuerDid?: string | null;
  credentialType?: string | null;
  proofSchemaVersion?: string | null;
}): Promise<void> {
  await writeAuditLog({
    action,
    actorUid,
    actorRole,
    targetType,
    targetId,
    companyId: companyId ?? null,
    metadata,
    extraFields: {
      verificationMethod: verificationMethod ?? null,
      issuerDid: issuerDid ?? null,
      credentialType: credentialType ?? null,
      proofSchemaVersion: proofSchemaVersion ?? null,
    },
  });
}
