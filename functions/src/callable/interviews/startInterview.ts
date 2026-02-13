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
import { JobOffer, Interview } from "../../types/models";

const logger = createLogger({ function: "startInterview" });

function pickNonEmptyString(...values: unknown[]): string | undefined {
  for (const value of values) {
    if (value === null || value === undefined) continue;
    const normalized = String(value).trim();
    if (normalized.length > 0) return normalized;
  }
  return undefined;
}

export const startInterview = functions.region("europe-west1").https.onCall(
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
        const application = appDoc.data() as Record<string, unknown>;
        const jobOfferId = pickNonEmptyString(
          application.job_offer_id,
          application.jobOfferId
        );
        const candidateUid = pickNonEmptyString(
          application.candidate_uid,
          application.candidateId,
          application.candidate_id
        );
        if (!jobOfferId) {
          throw new ValidationError("Application is missing job offer reference");
        }
        if (!candidateUid) {
          throw new ValidationError("Application is missing candidate reference");
        }

        // Verify Company Ownership
        // We check against job offer to be sure, or if application has companyUid
        const offerRef = db.collection("jobOffers").doc(jobOfferId);
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
          jobOfferId: jobOfferId,
          companyUid: companyUid,
          candidateUid: candidateUid,
          participants: [companyUid, candidateUid],
          status: "scheduling",
          createdAt: now,
          updatedAt: now,
        };

        transaction.set(interviewRef, interview);

        // 5. Update Application Status
        transaction.update(appRef, {
          status: "interview",
          updated_at: now,
          updatedAt: now,
          job_offer_id: jobOfferId,
          candidate_uid: candidateUid,
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
