/**
 * Callable Cloud Function: submitApplication
 *
 * Secure endpoint for submitting job applications.
 * Validates all data on the server side and prevents abuse.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { validateApplication, ValidationError } from "../../utils/validation";
import {
  SubmitApplicationRequest,
  SubmitApplicationResponse,
  Application,
} from "../../types/models";

const logger = createLogger({ function: "submitApplication" });

// Rate limiting: max applications per user per day
const MAX_APPLICATIONS_PER_DAY = 50;

export const submitApplication = functions.https.onCall(
  async (data: SubmitApplicationRequest, context): Promise<SubmitApplicationResponse> => {
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
    const { jobOfferId, coverLetter, curriculumId } = data;

    funcLogger.info("Application submission started", {
      candidateUid,
      jobOfferId,
    });

    try {
      const db = admin.firestore();

      // Validate input
      if (!jobOfferId || !curriculumId) {
        throw new ValidationError("jobOfferId and curriculumId are required");
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

      // Check if curriculum exists and belongs to user
      const curriculumDoc = await db
        .collection("curriculum")
        .doc(curriculumId)
        .get();

      if (!curriculumDoc.exists) {
        throw new ValidationError("Curriculum not found");
      }

      const curriculum = curriculumDoc.data();
      if (curriculum?.uid !== candidateUid) {
        throw new ValidationError("Curriculum does not belong to user");
      }

      // Check for existing applications to this job
      const existingApplications = await db
        .collection("applications")
        .where("job_offer_id", "==", jobOfferId)
        .where("candidate_uid", "==", candidateUid)
        .where("status", "in", ["submitted", "reviewed", "shortlisted"])
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
      const application: Omit<Application, "id" | "match_score"> = {
        job_offer_id: jobOfferId,
        candidate_uid: candidateUid,
        candidate_name: candidate.name,
        candidate_email: candidate.email,
        curriculum_id: curriculumId,
        cover_letter: coverLetter,
        status: "submitted",
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        submitted_at: now as any,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        updated_at: now as any,
      };

      // Validate application data
      validateApplication(application);

      // Create application document
      const applicationRef = await db.collection("applications").add(application);
      const applicationId = applicationRef.id;

      funcLogger.info("Application created successfully", {
        applicationId,
        candidateUid,
        jobOfferId,
      });

      // Return response
      const response: SubmitApplicationResponse = {
        applicationId,
        status: "submitted",
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
