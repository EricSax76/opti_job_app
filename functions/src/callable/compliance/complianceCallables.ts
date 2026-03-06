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

    return {
      id: docRef.id,
      status: "pending",
      dueAt: dueAt.toDate().toISOString(),
    };
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
    const requestRef = db.collection("dataRequests").doc(requestId);
    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Solicitud no encontrada.");
    }

    const request = asRecord(requestDoc.data());
    const companyId = asTrimmedString(request.companyId);
    if (!companyId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "La solicitud no tiene empresa responsable asociada.",
      );
    }

    const actorUid = context.auth.uid;
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

    await requestRef.update({
      status,
      response: response || null,
      processedBy: actorUid,
      processorRole: actorScope,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
      },
    }).catch(err => console.error("Audit log failed", err));

    return { success: true };
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
      legal_basis: "RGPD Art. 20 (Portability Rights)",
    };

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
      },
    }).catch(err => console.error("Audit log failed", err));

    return exportPackage;
  });
