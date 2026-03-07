import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {
  REQUEST_TYPES_SET,
  PROCESS_STATUSES_SET,
  FINALIST_STATUSES,
  asTrimmedString,
  asRecord,
  normalizeRequestType,
  normalizeProcessStatus,
  normalizeCandidateStatus,
} from "./utils/complianceUtils";
import { logAuditEntry } from "./utils/complianceAudit";
import { resolveCompanyAccess } from "./utils/complianceAccess";
import { recordComplianceOperation } from "./utils/complianceObservability";
import { ensureCallableResponseContract } from "../../utils/contractConventions";

function asDate(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof admin.firestore.Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  if (typeof value === "object" && value !== null) {
    const maybeTs = value as { toDate?: () => Date };
    if (typeof maybeTs.toDate === "function") {
      try {
        return maybeTs.toDate();
      } catch {
        return null;
      }
    }
  }
  return null;
}

function isTerminalRequestStatus(status: string): boolean {
  return status === "completed" || status === "denied";
}

/**
 * Submit a request to exercise ARSULIPO rights (GDPR) and AI Act rights.
 */
export const submitDataRequest = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const type = normalizeRequestType(data?.type);
    const description = asTrimmedString(data?.description);
    const requestMetadata = asRecord(data?.metadata);
    const inputCompanyId = asTrimmedString(data?.companyId);
    const inputApplicationId = asTrimmedString(data?.applicationId);

    if (!type || !REQUEST_TYPES_SET.has(type)) {
      throw new functions.https.HttpsError("invalid-argument", "Tipo de solicitud inválido.");
    }
    if (!description) {
      throw new functions.https.HttpsError("invalid-argument", "description is required.");
    }

    const db = admin.firestore();
    const candidateUid = context.auth.uid;
    let companyId = inputCompanyId;
    let applicationId = inputApplicationId;

    const requiresApplicationContext =
      type === "aiExplanation" || type === "salaryComparison";

    if (requiresApplicationContext) {
      if (!applicationId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "applicationId es obligatorio para solicitudes de IA o comparativa salarial.",
        );
      }
      const appDoc = await db.collection("applications").doc(applicationId).get();
      if (!appDoc.exists) {
        throw new functions.https.HttpsError("not-found", "La candidatura indicada no existe.");
      }
      const app = asRecord(appDoc.data());
      const appCandidateUid =
        asTrimmedString(app.candidate_uid) ||
        asTrimmedString(app.candidateId) ||
        asTrimmedString(app.candidate_id);
      if (appCandidateUid !== candidateUid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Solo puedes solicitar derechos sobre tus propias candidaturas.",
        );
      }

      companyId =
        companyId ||
        asTrimmedString(app.company_uid) ||
        asTrimmedString(app.companyUid) ||
        asTrimmedString(app.owner_uid);

      if (!companyId) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "No se pudo resolver la empresa responsable de la candidatura.",
        );
      }

      if (type === "salaryComparison") {
        const status = normalizeCandidateStatus(app.status);
        if (!FINALIST_STATUSES.has(status)) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "La comparativa salarial solo está disponible para candidaturas finalistas.",
          );
        }
      }
    }

    const now = admin.firestore.Timestamp.now();
    const dueAt = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + (30 * 24 * 60 * 60 * 1000),
    );

    const request = {
      candidateUid,
      companyId: companyId || null,
      applicationId: applicationId || null,
      type,
      status: "pending",
      description,
      metadata: requestMetadata,
      createdAt: now,
      dueAt,
      slaDays: 30,
    };

    const docRef = await db.collection("dataRequests").add(request);

    // Run audit logging asynchronously
    logAuditEntry({
      action: "data_request_submitted",
      actorUid: candidateUid,
      actorRole: "candidate",
      targetType: "data_request",
      targetId: docRef.id,
      companyId: companyId || null,
      metadata: {
        type,
        applicationId: applicationId || null,
      },
    }).catch(err => console.error("Audit log failed", err));

    return ensureCallableResponseContract(
      {
        id: docRef.id,
        status: "pending",
        dueAt: dueAt.toDate().toISOString(),
      },
      { callableName: "submitDataRequest" },
    );
  });

/**
 * Process an ARSULIPO/AI Act request by a company or authorized recruiter.
 */
export const processDataRequest = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const requestId = asTrimmedString(data?.requestId);
    const status = normalizeProcessStatus(data?.status);
    const response = asTrimmedString(data?.response);

    if (!requestId || !status) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "requestId and status are required.",
      );
    }
    if (!PROCESS_STATUSES_SET.has(status)) {
      throw new functions.https.HttpsError("invalid-argument", "Estado de solicitud inválido.");
    }

    const db = admin.firestore();
    const actorUid = context.auth.uid;
    const startedAt = Date.now();
    let companyIdForMetrics: string | null = null;
    let candidateUidForMetrics: string | null = null;

    try {
      const requestRef = db.collection("dataRequests").doc(requestId);
      const requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Solicitud no encontrada.");
      }

      const request = asRecord(requestDoc.data());
      const companyId = asTrimmedString(request.companyId);
      companyIdForMetrics = companyId || null;
      candidateUidForMetrics = asTrimmedString(request.candidateUid) || null;
      if (!companyId) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "La solicitud no tiene empresa responsable asociada.",
        );
      }

      const actorScope = await resolveCompanyAccess({ actorUid, companyId });

      if (
        asTrimmedString(request.type) === "salaryComparison" &&
        status === "completed" &&
        !response
      ) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Debes incluir respuesta con los datos comparativos para cerrar la solicitud.",
        );
      }

      const nowDate = new Date();
      const requestCreatedAt = asDate(request.createdAt);
      const requestDueAt = asDate(request.dueAt);
      const requestAgeMs = requestCreatedAt
        ? Math.max(0, nowDate.getTime() - requestCreatedAt.getTime())
        : null;
      const terminalStatus = isTerminalRequestStatus(status);
      const resolvedWithinSla = terminalStatus && requestDueAt
        ? nowDate.getTime() <= requestDueAt.getTime()
        : null;
      const slaBreached = resolvedWithinSla === false;

      const updatePayload: Record<string, unknown> = {
        status,
        response: response || null,
        processedBy: actorUid,
        processorRole: actorScope,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (requestAgeMs !== null) {
        updatePayload.requestAgeMs = requestAgeMs;
      }
      if (terminalStatus) {
        updatePayload.resolvedWithinSla = resolvedWithinSla;
        updatePayload.slaBreached = slaBreached;
      }

      await requestRef.update(updatePayload);

      const callableLatencyMs = Math.max(0, Date.now() - startedAt);

      await recordComplianceOperation({
        db,
        operation: "processDataRequest",
        outcome: "success",
        actorUid,
        candidateUid: candidateUidForMetrics,
        companyId,
        requestId,
        latencyMs: callableLatencyMs,
        resolvedWithinSla,
        slaBreached,
        metadata: {
          status,
          actorScope,
          responseIncluded: response.length > 0,
          requestAgeMs,
        },
      });

      // Run audit logging asynchronously
      logAuditEntry({
        action: "data_request_processed",
        actorUid,
        actorRole: actorScope === "company" ? "company" : "recruiter",
        targetType: "data_request",
        targetId: requestId,
        companyId,
        metadata: {
          status,
          responseIncluded: response.length > 0,
          latencyMs: callableLatencyMs,
          requestAgeMs,
          resolvedWithinSla,
          slaBreached,
        },
      }).catch(err => console.error("Audit log failed", err));

      return ensureCallableResponseContract(
        { success: true },
        { callableName: "processDataRequest" },
      );
    } catch (error) {
      const callableLatencyMs = Math.max(0, Date.now() - startedAt);
      const errorCode = error instanceof functions.https.HttpsError
        ? error.code
        : "internal";

      await recordComplianceOperation({
        db,
        operation: "processDataRequest",
        outcome: "error",
        actorUid,
        candidateUid: candidateUidForMetrics,
        companyId: companyIdForMetrics,
        requestId,
        latencyMs: callableLatencyMs,
        errorCode,
        metadata: {
          status,
        },
      }).catch((obsError) => {
        console.error("Compliance observability failed (processDataRequest):", obsError);
      });

      logAuditEntry({
        action: "data_request_process_failed",
        actorUid,
        actorRole: companyIdForMetrics && actorUid === companyIdForMetrics
          ? "company"
          : "recruiter",
        targetType: "data_request",
        targetId: requestId,
        companyId: companyIdForMetrics,
        metadata: {
          status,
          errorCode,
          latencyMs: callableLatencyMs,
        },
      }).catch((auditErr) => console.error("Audit log failed", auditErr));

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Error processing data request:", error);
      throw new functions.https.HttpsError(
        "internal",
        "No se pudo procesar la solicitud de privacidad.",
      );
    }
  });

/**
 * Export all candidate data for portability (JSON), including recruiter notes.
 */
export const exportCandidateData = functions
  .region("europe-west1")
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const candidateUid = context.auth.uid;
    const db = admin.firestore();
    const startedAt = Date.now();

    try {
      const [curriculum, appsByCamel, appsBySnake, consents, notes, requests] =
        await Promise.all([
          db.collection("candidates").doc(candidateUid).collection("curriculum").limit(200).get(),
          db.collection("applications").where("candidateId", "==", candidateUid).limit(200).get(),
          db.collection("applications").where("candidate_uid", "==", candidateUid).limit(200).get(),
          db.collection("consentRecords").where("candidateUid", "==", candidateUid).limit(200).get(),
          db.collection("candidateNotes").where("candidateUid", "==", candidateUid).limit(200).get(),
          db.collection("dataRequests").where("candidateUid", "==", candidateUid).limit(200).get(),
        ]);

      const dedupedApplications = new Map<string, Record<string, unknown>>();
      for (const appDoc of [...appsByCamel.docs, ...appsBySnake.docs]) {
        dedupedApplications.set(appDoc.id, appDoc.data() as Record<string, unknown>);
      }

      const exportPackage = {
        candidateUid,
        exportedAt: new Date().toISOString(),
        curriculum: curriculum.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Record<string, unknown>),
        })),
        applications: [...dedupedApplications.values()],
        consents: consents.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Record<string, unknown>),
        })),
        candidateNotes: notes.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Record<string, unknown>),
        })),
        dataRequests: requests.docs.map((d) => ({
          id: d.id,
          ...(d.data() as Record<string, unknown>),
        })),
        metadata: {
          applicationsCount: dedupedApplications.size,
          curriculumDocsCount: curriculum.size,
          consentRecordsCount: consents.size,
          candidateNotesCount: notes.size,
          dataRequestsCount: requests.size,
        },
        legalBasis: "RGPD Art. 20 (Portability Rights)",
      };

      const callableLatencyMs = Math.max(0, Date.now() - startedAt);

      await recordComplianceOperation({
        db,
        operation: "exportCandidateData",
        outcome: "success",
        actorUid: candidateUid,
        candidateUid,
        companyId: null,
        requestId: null,
        latencyMs: callableLatencyMs,
        metadata: {
          applications: dedupedApplications.size,
          notes: notes.size,
          requests: requests.size,
        },
      });

      // Run audit logging asynchronously
      logAuditEntry({
        action: "candidate_data_exported",
        actorUid: candidateUid,
        actorRole: "candidate",
        targetType: "candidate",
        targetId: candidateUid,
        metadata: {
          applications: dedupedApplications.size,
          notes: notes.size,
          requests: requests.size,
          latencyMs: callableLatencyMs,
        },
      }).catch(err => console.error("Audit log failed", err));

      return ensureCallableResponseContract(exportPackage, {
        callableName: "exportCandidateData",
        deep: false,
      });
    } catch (error) {
      const callableLatencyMs = Math.max(0, Date.now() - startedAt);
      const errorCode = error instanceof functions.https.HttpsError
        ? error.code
        : "internal";

      await recordComplianceOperation({
        db,
        operation: "exportCandidateData",
        outcome: "error",
        actorUid: candidateUid,
        candidateUid,
        companyId: null,
        requestId: null,
        latencyMs: callableLatencyMs,
        errorCode,
      }).catch((obsError) => {
        console.error("Compliance observability failed (exportCandidateData):", obsError);
      });

      logAuditEntry({
        action: "candidate_data_export_failed",
        actorUid: candidateUid,
        actorRole: "candidate",
        targetType: "candidate",
        targetId: candidateUid,
        metadata: {
          errorCode,
          latencyMs: callableLatencyMs,
        },
      }).catch((auditErr) => console.error("Audit log failed", auditErr));

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error("Error exporting candidate data:", error);
      throw new functions.https.HttpsError(
        "internal",
        "No se pudo exportar tus datos personales.",
      );
    }
  });
