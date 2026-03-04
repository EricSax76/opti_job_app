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
    const normalizedSource = String(sourceChannel ?? "").trim().toLowerCase() || "platform";
    const normalizedCurriculumId = String(curriculumId ?? "main").trim() || "main";

    funcLogger.info("Application submission started", {
      candidateUid,
      jobOfferId,
    });

    try {
      const db = admin.firestore();

      // Validate input
      if (!jobOfferId) {
        throw new ValidationError("jobOfferId is required");
      }

      // Check if job offer exists and is active
      const offerDoc = await db.collection("jobOffers").doc(jobOfferId).get();
      if (!offerDoc.exists) {
        throw new ValidationError("Job offer not found");
      }

      const jobOffer = offerDoc.data();
      if (jobOffer?.status !== "active") {
        throw new ValidationError(
          `Job offer is not active (status: ${jobOffer?.status})`
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

      // Check for existing applications to this job
      const existingApplications = await db
        .collection("applications")
        .where("job_offer_id", "==", jobOfferId)
        .where("candidate_uid", "==", candidateUid)
        .where("status", "in", ["submitted", "pending", "reviewing", "interviewing", "offered", "hired"])
        .get();

      if (!existingApplications.empty) {
        funcLogger.warn("Duplicate application attempt", {
          candidateUid,
          jobOfferId,
          existingApplicationId: existingApplications.docs[0].id,
        });
        throw new ValidationError(
          "You have already applied to this job offer"
        );
      }

      // Rate limiting: check applications in last 24 hours
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      const recentApplications = await db
        .collection("applications")
        .where("candidate_uid", "==", candidateUid)
        .where("submitted_at", ">=", admin.firestore.Timestamp.fromDate(yesterday))
        .get();

      if (recentApplications.size >= MAX_APPLICATIONS_PER_DAY) {
        funcLogger.warn("Rate limit exceeded", {
          candidateUid,
          applicationsCount: recentApplications.size,
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
        job_offer_id: jobOfferId,
        jobOfferId: jobOfferId,
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
        `Oferta: ${jobOffer?.title ?? jobOfferId}`,
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
          jobOfferId,
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
          jobOfferId,
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
            jobOfferId,
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
        jobOfferId,
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
