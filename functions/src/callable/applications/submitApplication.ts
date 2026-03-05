/**
 * Callable Cloud Function: submitApplication
 *
 * Secure endpoint for submitting job applications.
 * Validates all data on the server side and prevents abuse.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { validateApplication, ValidationError } from "../../utils/validation";
import {
  SubmitApplicationRequest,
  SubmitApplicationResponse,
} from "../../types/models";

const logger = createLogger({ function: "submitApplication" });

// Rate limiting: max applications per user per day
const MAX_APPLICATIONS_PER_DAY = 50;
const RATE_LIMIT_WINDOW_MS = 24 * 60 * 60 * 1000;
const BLOCKING_APPLICATION_STATUSES = new Set([
  "submitted",
  "pending",
  "reviewing",
  "interviewing",
  "offered",
  "accepted_pending_signature",
  "hired",
]);

function normalizeString(value: unknown): string {
  return String(value ?? "").trim();
}

function normalizeLower(value: unknown): string {
  return normalizeString(value).toLowerCase();
}

function parseDate(value: unknown): Date | null {
  if (value == null) return null;
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (typeof value === "object" && value !== null) {
    const maybeWithToDate = value as { toDate?: unknown };
    if (typeof maybeWithToDate.toDate === "function") {
      try {
        const parsed = maybeWithToDate.toDate.call(value) as unknown;
        if (parsed instanceof Date && !Number.isNaN(parsed.getTime())) {
          return parsed;
        }
      } catch (_) {
        // Ignore malformed timestamp-like values.
      }
    }
  }
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

export const submitApplication = functions.region("europe-west1").https.onCall(
  async (
    data: SubmitApplicationRequest,
    context: functions.https.CallableContext
  ): Promise<SubmitApplicationResponse> => {
    const requestId = Math.random().toString(36).substring(7);
    const funcLogger = logger.withContext({ requestId });

    // Verify authentication
    if (!context.auth) {
      funcLogger.warn("Unauthenticated request");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to submit applications"
      );
    }

    const candidateUid = context.auth.uid;
    const { jobOfferId, coverLetter, curriculumId, sourceChannel } = data;
    const requestedJobOfferId = normalizeString(jobOfferId);
    const normalizedSource = normalizeLower(sourceChannel) || "platform";
    const normalizedCurriculumId = normalizeString(curriculumId || "main") || "main";

    funcLogger.info("Application submission started", {
      candidateUid,
      requestedJobOfferId,
    });

    try {
      const db = admin.firestore();

      // Validate input
      if (!requestedJobOfferId) {
        throw new ValidationError("jobOfferId is required");
      }

      // Resolve offer first by document ID and then by legacy "id" field.
      let resolvedJobOfferId = requestedJobOfferId;
      let offerDoc = await db.collection("jobOffers").doc(resolvedJobOfferId).get();
      if (!offerDoc.exists) {
        const offerIdCandidates: unknown[] = [requestedJobOfferId];
        const numericRequestedId = Number.parseInt(requestedJobOfferId, 10);
        if (Number.isFinite(numericRequestedId)) {
          offerIdCandidates.push(numericRequestedId);
        }

        const legacyOfferSnapshot = await db
          .collection("jobOffers")
          .where("id", "in", offerIdCandidates)
          .limit(1)
          .get();
        if (legacyOfferSnapshot.empty) {
          throw new ValidationError("Job offer not found");
        }

        offerDoc = legacyOfferSnapshot.docs[0];
        resolvedJobOfferId = offerDoc.id;
      }

      const jobOffer = offerDoc.data();
      if (!jobOffer) {
        throw new ValidationError("Job offer not found");
      }
      const offerStatus = String(jobOffer?.status ?? "").trim().toLowerCase();
      const isOfferOpenForApplications =
        offerStatus.length === 0 ||
        offerStatus === "active" ||
        offerStatus === "published";
      if (!isOfferOpenForApplications) {
        throw new ValidationError(
          `Job offer is not active (status: ${jobOffer?.status ?? "undefined"})`
        );
      }

      // Check if offer is expired
      if (jobOffer.expires_at) {
        const expiresAt = jobOffer.expires_at.toDate();
        if (expiresAt < new Date()) {
          throw new ValidationError("Job offer has expired");
        }
      }

      // Check if curriculum exists and belongs to user at canonical path:
      // candidates/{uid}/curriculum/{id}. Fallback to "main".
      let resolvedCurriculumId = normalizedCurriculumId;
      let curriculumDoc = await db
        .collection("candidates")
        .doc(candidateUid)
        .collection("curriculum")
        .doc(resolvedCurriculumId)
        .get();

      if (!curriculumDoc.exists && resolvedCurriculumId !== "main") {
        resolvedCurriculumId = "main";
        curriculumDoc = await db
          .collection("candidates")
          .doc(candidateUid)
          .collection("curriculum")
          .doc(resolvedCurriculumId)
          .get();
      }

      if (!curriculumDoc.exists) {
        throw new ValidationError("Curriculum not found");
      }

      const [applicationsByCandidateUid, applicationsByCandidateId] = await Promise.all([
        db.collection("applications").where("candidate_uid", "==", candidateUid).get(),
        db.collection("applications").where("candidateId", "==", candidateUid).get(),
      ]);

      const offerIdAliases = new Set<string>(
        [requestedJobOfferId, resolvedJobOfferId]
          .map((value) => normalizeString(value))
          .filter((value) => value.length > 0)
      );
      let duplicateApplicationId: string | null = null;
      const visitedForDuplicate = new Set<string>();

      const detectDuplicate = (
        snapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>
      ): void => {
        for (const doc of snapshot.docs) {
          if (visitedForDuplicate.has(doc.id)) continue;
          visitedForDuplicate.add(doc.id);
          const row = doc.data();
          const status = normalizeLower(row.status);
          if (!BLOCKING_APPLICATION_STATUSES.has(status)) continue;

          const appOfferId = normalizeString(row.job_offer_id ?? row.jobOfferId);
          if (!appOfferId || !offerIdAliases.has(appOfferId)) continue;
          duplicateApplicationId = doc.id;
          break;
        }
      };

      detectDuplicate(applicationsByCandidateUid);
      if (duplicateApplicationId == null) {
        detectDuplicate(applicationsByCandidateId);
      }

      if (duplicateApplicationId != null) {
        funcLogger.warn("Duplicate application attempt", {
          candidateUid,
          requestedJobOfferId,
          resolvedJobOfferId,
          existingApplicationId: duplicateApplicationId,
        });
        throw new ValidationError(
          "You have already applied to this job offer"
        );
      }

      // Rate limiting without composite indexes: count candidate applications
      // in the last 24h from either snake_case or camelCase timestamps.
      const rateLimitCutoff = new Date(Date.now() - RATE_LIMIT_WINDOW_MS);
      const visitedForRateLimit = new Set<string>();
      let recentApplicationsCount = 0;
      const countRecentApplications = (
        snapshot: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>
      ): void => {
        for (const doc of snapshot.docs) {
          if (visitedForRateLimit.has(doc.id)) continue;
          visitedForRateLimit.add(doc.id);
          const row = doc.data();
          const submittedAt = parseDate(
            row.submitted_at ??
              row.submittedAt ??
              row.created_at ??
              row.createdAt
          );
          if (submittedAt != null && submittedAt >= rateLimitCutoff) {
            recentApplicationsCount += 1;
          }
        }
      };

      countRecentApplications(applicationsByCandidateUid);
      countRecentApplications(applicationsByCandidateId);

      if (recentApplicationsCount >= MAX_APPLICATIONS_PER_DAY) {
        funcLogger.warn("Rate limit exceeded", {
          candidateUid,
          applicationsCount: recentApplicationsCount,
        });
        throw new ValidationError(
          `Daily application limit exceeded (${MAX_APPLICATIONS_PER_DAY})`
        );
      }

      // Get candidate info
      const candidateDoc = await db.collection("candidates").doc(candidateUid).get();
      const candidate = candidateDoc.data();

      if (!candidate) {
        throw new ValidationError("Candidate profile not found");
      }

      // Create application
      const now = admin.firestore.FieldValue.serverTimestamp();
      const companyUid =
        jobOffer?.company_uid ?? jobOffer?.companyUid ?? jobOffer?.owner_uid;
      const application: Record<string, unknown> = {
        job_offer_id: resolvedJobOfferId,
        jobOfferId: resolvedJobOfferId,
        candidate_uid: candidateUid,
        candidateId: candidateUid,
        candidate_name: candidate.name,
        candidateName: candidate.name,
        candidate_email: candidate.email,
        candidateEmail: candidate.email,
        curriculum_id: resolvedCurriculumId,
        curriculumId: resolvedCurriculumId,
        source_channel: normalizedSource,
        sourceChannel: normalizedSource,
        source: normalizedSource,
        status: "pending",
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        submitted_at: now as any,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        updated_at: now as any,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        submittedAt: now as any,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        updatedAt: now as any,
      };

      if (coverLetter !== undefined) {
        application.cover_letter = coverLetter;
        application.coverLetter = coverLetter;
      }

      if (companyUid !== undefined && companyUid !== null) {
        application.company_uid = companyUid;
        application.companyUid = companyUid;
      }

      // Validate application data
      validateApplication(application);

      // Create application document
      const applicationRef = await db.collection("applications").add(application);
      const applicationId = applicationRef.id;

      const legalInfoClause =
        "Tus datos se tratarán para gestionar la candidatura y evaluar tu encaje con la vacante. " +
        "Base jurídica: ejecución de medidas precontractuales y, en su caso, consentimiento. " +
        "Puedes ejercer ARSULIPO y solicitar explicación humana de decisiones de IA desde el portal de privacidad.";
      const legalAckSubject = "Hemos recibido tu candidatura";
      const legalAckBody = [
        `Solicitud: ${requestId}`,
        `Oferta: ${jobOffer?.title ?? resolvedJobOfferId}`,
        "Acuse de recibo legal de candidatura:",
        legalInfoClause,
      ].join("\n");

      await Promise.all([
        db.collection("notifications").add({
          type: "application_received_legal_ack",
          channel: "in_app",
          audience: "candidate",
          userUid: candidateUid,
          companyUid: companyUid ?? null,
          applicationId,
          jobOfferId: resolvedJobOfferId,
          title: legalAckSubject,
          message: legalAckBody,
          legalInfoClause,
          read: false,
          createdAt: now,
          updatedAt: now,
        }),
        db.collection("emailQueue").add({
          to: candidate.email,
          template: "application_received_legal_ack",
          subject: legalAckSubject,
          text: legalAckBody,
          candidateUid,
          companyUid: companyUid ?? null,
          applicationId,
          jobOfferId: resolvedJobOfferId,
          legalInfoClause,
          status: "queued",
          createdAt: now,
          updatedAt: now,
        }),
        db.collection("auditLogs").add({
          action: "application_legal_ack_sent",
          actorUid: "system",
          actorRole: "system",
          targetType: "application",
          targetId: applicationId,
          companyId: companyUid ?? null,
          metadata: {
            requestId,
            candidateUid,
            requestedJobOfferId,
            resolvedJobOfferId,
            notificationChannel: "in_app",
            emailQueued: true,
            legalInfoClauseVersion: "2026-03",
          },
          timestamp: now,
        }),
      ]);

      funcLogger.info("Application created successfully", {
        applicationId,
        candidateUid,
        requestedJobOfferId,
        resolvedJobOfferId,
      });

      // Return response
      const response: SubmitApplicationResponse = {
        applicationId,
        status: "pending",
        submittedAt: admin.firestore.Timestamp.now() as FirebaseFirestore.Timestamp,
      };

      // TODO: Calculate match score asynchronously
      // This could be done by another function or background task

      return response;
    } catch (error) {
      funcLogger.error("Error submitting application", error);

      if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }

      throw new functions.https.HttpsError(
        "internal",
        "Failed to submit application"
      );
    }
  }
);
