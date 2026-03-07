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

export const submitApplication = functions
  .runWith({ memory: "512MB", timeoutSeconds: 120, minInstances: 1 })
  .region("europe-west1")
  .https.onCall(
    async (
      data: SubmitApplicationRequest,
      context: functions.https.CallableContext
    ): Promise<SubmitApplicationResponse> => {
      const funcLogger = logger.withContext({
        requestId: Math.random().toString(36).substring(7),
      });

      // ── Auth ──────────────────────────────────────────────────────
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
      const normalizedCurriculumId =
        normalizeString(curriculumId || "main") || "main";

      funcLogger.info("Application submission started", {
        candidateUid,
        requestedJobOfferId,
      });

      try {
        const db = admin.firestore();

        if (!requestedJobOfferId) {
          throw new ValidationError("jobOfferId is required");
        }

        // ── Phase 1: parallel reads (offer + curriculum + candidate) ──
        const [offerDocResult, curriculumDocResult, candidateDoc] =
          await Promise.all([
            db.collection("jobOffers").doc(requestedJobOfferId).get(),
            db
              .collection("candidates")
              .doc(candidateUid)
              .collection("curriculum")
              .doc(normalizedCurriculumId)
              .get(),
            db.collection("candidates").doc(candidateUid).get(),
          ]);

        // Resolve offer — fallback to legacy "id" field if doc ID miss
        let offerDoc = offerDocResult;
        let resolvedJobOfferId = requestedJobOfferId;

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

        // Validate offer status
        const offerStatus = String(jobOffer?.status ?? "")
          .trim()
          .toLowerCase();
        const isOfferOpenForApplications =
          offerStatus.length === 0 ||
          offerStatus === "active" ||
          offerStatus === "published";
        if (!isOfferOpenForApplications) {
          throw new ValidationError(
            `Job offer is not active (status: ${jobOffer?.status ?? "undefined"})`
          );
        }

        // Check offer expiry
        if (jobOffer.expires_at) {
          const expiresAt = parseDate(jobOffer.expires_at);
          if (expiresAt && expiresAt < new Date()) {
            throw new ValidationError("Job offer has expired");
          }
        }

        // Resolve curriculum — fallback to "main"
        let curriculumDoc = curriculumDocResult;
        let resolvedCurriculumId = normalizedCurriculumId;
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

        // Validate candidate
        const candidate = candidateDoc.data();
        if (!candidate) {
          throw new ValidationError("Candidate profile not found");
        }
        const candidateRecord = candidate as Record<string, unknown>;
        const candidateVideo = candidateRecord.video_curriculum as
          | Record<string, unknown>
          | undefined;
        const hasVideoCurriculum =
          candidateVideo != null &&
          normalizeString(candidateVideo.storage_path).length > 0;

        // ── Phase 2: targeted duplicate check + rate limit (parallel) ──
        const offerIdAliases = [
          ...new Set(
            [requestedJobOfferId, resolvedJobOfferId]
              .map(normalizeString)
              .filter((v) => v.length > 0)
          ),
        ];
        const rateLimitCutoff = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - RATE_LIMIT_WINDOW_MS)
        );

        // Build targeted duplicate queries using compound filters + limit
        const dupQueries: Promise<
          FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>
        >[] = [];
        for (const offerId of offerIdAliases) {
          dupQueries.push(
            db
              .collection("applications")
              .where("candidate_uid", "==", candidateUid)
              .where("job_offer_id", "==", offerId)
              .limit(5)
              .get(),
            db
              .collection("applications")
              .where("candidateId", "==", candidateUid)
              .where("jobOfferId", "==", offerId)
              .limit(5)
              .get()
          );
        }

        const [rateLimitSnapshot, ...dupSnapshots] = await Promise.all([
          // Server-side count — no document downloads
          db
            .collection("applications")
            .where("candidate_uid", "==", candidateUid)
            .where("submitted_at", ">=", rateLimitCutoff)
            .count()
            .get(),
          ...dupQueries,
        ]);

        // Check duplicates across snapshots (deduped by doc id)
        const visitedDup = new Set<string>();
        let duplicateApplicationId: string | null = null;
        for (const snap of dupSnapshots) {
          if (duplicateApplicationId) break;
          for (const doc of snap.docs) {
            if (visitedDup.has(doc.id)) continue;
            visitedDup.add(doc.id);
            const status = normalizeLower(doc.data().status);
            if (BLOCKING_APPLICATION_STATUSES.has(status)) {
              duplicateApplicationId = doc.id;
              break;
            }
          }
        }

        if (duplicateApplicationId) {
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

        // Check rate limit (server-side aggregation — no docs downloaded)
        const recentApplicationsCount = rateLimitSnapshot.data().count;
        if (recentApplicationsCount >= MAX_APPLICATIONS_PER_DAY) {
          funcLogger.warn("Rate limit exceeded", {
            candidateUid,
            applicationsCount: recentApplicationsCount,
          });
          throw new ValidationError(
            `Daily application limit exceeded (${MAX_APPLICATIONS_PER_DAY})`
          );
        }

        // ── Phase 3: create application ─────────────────────────────
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
          has_video_curriculum: hasVideoCurriculum,
          hasVideoCurriculum: hasVideoCurriculum,
        };

        if (coverLetter !== undefined) {
          application.cover_letter = coverLetter;
          application.coverLetter = coverLetter;
        }

        if (companyUid !== undefined && companyUid !== null) {
          application.company_uid = companyUid;
          application.companyUid = companyUid;
        }

        validateApplication(application);

        const applicationRef = await db
          .collection("applications")
          .add(application);

        // Legal ack (notification + emailQueue + auditLog) is handled
        // asynchronously by the onApplicationCreate trigger to reduce
        // user-facing latency.

        funcLogger.info("Application created successfully", {
          applicationId: applicationRef.id,
          candidateUid,
          requestedJobOfferId,
          resolvedJobOfferId,
        });

        return {
          applicationId: applicationRef.id,
          status: "pending",
          submittedAt:
            admin.firestore.Timestamp.now() as FirebaseFirestore.Timestamp,
        };
      } catch (error) {
        funcLogger.error("Error submitting application", error);

        if (error instanceof ValidationError) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            error.message
          );
        }

        throw new functions.https.HttpsError(
          "internal",
          "Failed to submit application"
        );
      }
    }
  );
