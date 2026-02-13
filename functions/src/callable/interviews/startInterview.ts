/**
 * Callable Function: startInterview
 *
 * Initiates an interview process for a candidate application.
 * - Verifies company ownership
 * - Creates interview document (idempotent: ID = applicationId)
 * - Updates application status to "interview"
 * - Adds initial system message
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { ValidationError } from "../../utils/validation";
import { Application, JobOffer, Interview } from "../../types/models";

const logger = createLogger({ function: "startInterview" });

export const startInterview = functions.https.onCall(
  async (
    data: { applicationId: string },
    context: functions.https.CallableContext
  ): Promise<{ interviewId: string }> => {
    // 1. Auth Check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }
    const companyUid = context.auth.uid;
    const { applicationId } = data;

    if (!applicationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "applicationId is required"
      );
    }

    const db = admin.firestore();
    const loggerCtx = { applicationId, companyUid };
    logger.info("Starting interview process", loggerCtx);

    try {
      await db.runTransaction(async (transaction) => {
        // 2. Fetch Application & Job Offer
        const appRef = db.collection("applications").doc(applicationId);
        const appDoc = await transaction.get(appRef);

        if (!appDoc.exists) {
          throw new ValidationError("Application not found");
        }
        const application = appDoc.data() as Application;

        // Verify Company Ownership
        // We check against job offer to be sure, or if application has companyUid
        const offerRef = db.collection("jobOffers").doc(application.job_offer_id);
        const offerDoc = await transaction.get(offerRef);
        
        if (!offerDoc.exists) {
           throw new ValidationError("Job offer not found");
        }
        const offer = offerDoc.data() as JobOffer;
        
        // Check if the requester is the company owner
        // Support both old and new field names if necessary, but models.ts says company_uid
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const offerOwner = offer.company_uid || (offer as any).companyUid || (offer as any).owner_uid;
        if (offerOwner !== companyUid) {
          throw new functions.https.HttpsError(
            "permission-denied",
            "Only the job offer owner can start an interview"
          );
        }

        // 3. Check for existing interview (Idempotency)
        const interviewRef = db.collection("interviews").doc(applicationId);
        const interviewDoc = await transaction.get(interviewRef);

        if (interviewDoc.exists) {
          logger.info("Interview already exists", loggerCtx);
          return; // Already created, just return (idempotent)
        }

        // 4. Create Interview Document
        const now = admin.firestore.Timestamp.now();
        const interview: Interview = {
          id: applicationId,
          applicationId: applicationId,
          jobOfferId: application.job_offer_id,
          companyUid: companyUid,
          candidateUid: application.candidate_uid,
          participants: [companyUid, application.candidate_uid],
          status: "scheduling",
          createdAt: now,
          updatedAt: now,
        };

        transaction.set(interviewRef, interview);

        // 5. Update Application Status
        transaction.update(appRef, {
          status: "interview",
          updated_at: now,
        });

        // 6. Add System Message
        const messagesRef = interviewRef.collection("messages").doc();
        transaction.set(messagesRef, {
          id: messagesRef.id,
          senderUid: companyUid,
          content: "Interview process started. Please propose a date.",
          type: "system",
          createdAt: now,
        });
      });

      logger.info("Interview started successfully", loggerCtx);
      return { interviewId: applicationId };

    } catch (error) {
      logger.error("Error starting interview", error, loggerCtx);
      if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "Failed to start interview");
    }
  }
);
