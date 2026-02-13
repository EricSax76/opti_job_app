/**
 * Callable Function: markInterviewSeen
 *
 * Marks an interview as seen by the user.
 * - Resets unread count for the user to 0.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { ValidationError } from "../../utils/validation";
import { Interview } from "../../types/models";

const logger = createLogger({ function: "markInterviewSeen" });

export const markInterviewSeen = functions.region("europe-west1").https.onCall(
  async (
    data: { interviewId: string },
    context: functions.https.CallableContext
  ): Promise<void> => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const uid = context.auth.uid;
    const { interviewId } = data;

    if (!interviewId) {
      throw new functions.https.HttpsError("invalid-argument", "interviewId is required");
    }

    const db = admin.firestore();
    const loggerCtx = { interviewId, uid };

    try {
      const interviewRef = db.collection("interviews").doc(interviewId);
      
      // We can use a simple update here, or transaction if we want to be super safe about concurrency,
      // but resetting to 0 is idempotent and usually safe enough.
      // However, to check participation, we need to read it.
      
      await db.runTransaction(async (transaction) => {
         const interviewDoc = await transaction.get(interviewRef);
         if (!interviewDoc.exists) {
            throw new ValidationError("Interview not found");
         }
         const interview = interviewDoc.data() as Interview;
         
         if (!interview.participants.includes(uid)) {
            throw new functions.https.HttpsError("permission-denied", "User is not a participant");
         }
         
         // Only update if count > 0 to save writes
         const currentCount = interview.unreadCounts?.[uid] || 0;
         if (currentCount > 0) {
            transaction.update(interviewRef, {
               [`unreadCounts.${uid}`]: 0
            });
         }
      });

    } catch (error) {
       logger.error("Error marking interview seen", error, loggerCtx);
      if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "Failed to mark seen");
    }
  }
);
