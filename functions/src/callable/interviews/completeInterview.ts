/**
 * Callable Function: completeInterview
 *
 * Marks an interview as completed.
 * - Updates status to "completed"
 * - Adds a system message
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { ValidationError } from "../../utils/validation";
import { Interview, Message } from "../../types/models";

const logger = createLogger({ function: "completeInterview" });

export const completeInterview = functions.region("europe-west1").https.onCall(
  async (
    data: { interviewId: string; notes?: string },
    context: functions.https.CallableContext
  ): Promise<void> => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const uid = context.auth.uid;
    const { interviewId, notes } = data;

    if (!interviewId) {
      throw new functions.https.HttpsError("invalid-argument", "interviewId is required");
    }

    const db = admin.firestore();
    const loggerCtx = { interviewId, uid };

    try {
      await db.runTransaction(async (transaction) => {
        const interviewRef = db.collection("interviews").doc(interviewId);
        const interviewDoc = await transaction.get(interviewRef);

        if (!interviewDoc.exists) {
           throw new ValidationError("Interview not found");
        }
        const interview = interviewDoc.data() as Interview;

        if (!interview.participants.includes(uid)) {
           throw new functions.https.HttpsError("permission-denied", "User is not a participant");
        }
        
        // Only company usually completes? Or both? Assuming Company for now, or just participant.
        // Let's restrict complete to CompanyOwner if we want, but checking participant is safer MVP.
        // Actually, typically only the company completes an interview process.
        if (interview.companyUid !== uid) {
            throw new functions.https.HttpsError("permission-denied", "Only company can complete the interview");
        }

        const now = admin.firestore.Timestamp.now();
        
        // Update Interview Status
        transaction.update(interviewRef, {
          status: "completed",
          updatedAt: now,
        });

        // Add System Message
        const messagesRef = interviewRef.collection("messages").doc();
        const message: Message = {
            id: messagesRef.id,
            senderUid: uid,
            content: `Interview marked as completed. ${notes ? `Notes: ${notes}` : ''}`,
            type: 'system',
            createdAt: now,
        };
        transaction.set(messagesRef, message);
      });

    } catch (error) {
       logger.error("Error completing interview", error, loggerCtx);
      if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "Failed to complete interview");
    }
  }
);
