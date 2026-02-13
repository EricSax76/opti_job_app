/**
 * Callable Function: proposeInterviewSlot
 *
 * Proposes a date and time for the interview.
 * - Adds a "proposal" typed message
 * - Validates future date
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { ValidationError } from "../../utils/validation";
import { Interview, Message } from "../../types/models";

const logger = createLogger({ function: "proposeInterviewSlot" });

export const proposeInterviewSlot = functions.region("europe-west1").https.onCall(
  async (
    data: { interviewId: string; proposedAt: string; timeZone: string },
    context: functions.https.CallableContext
  ): Promise<{ messageId: string }> => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const senderUid = context.auth.uid;
    const { interviewId, proposedAt, timeZone } = data;

    if (!interviewId || !proposedAt || !timeZone) {
      throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
    }

    const proposedDate = new Date(proposedAt);
    if (isNaN(proposedDate.getTime()) || proposedDate < new Date()) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid or past date");
    }

    const db = admin.firestore();
    const loggerCtx = { interviewId, senderUid };

    try {
      await db.runTransaction(async (transaction) => {
        const interviewRef = db.collection("interviews").doc(interviewId);
        const interviewDoc = await transaction.get(interviewRef);

        if (!interviewDoc.exists) {
           throw new ValidationError("Interview not found");
        }
        const interview = interviewDoc.data() as Interview;

        if (!interview.participants.includes(senderUid)) {
           throw new functions.https.HttpsError("permission-denied", "User is not a participant");
        }

        const now = admin.firestore.Timestamp.now();
        const proposedTimestamp = admin.firestore.Timestamp.fromDate(proposedDate);
        
        // Add Proposal Message
        const messagesRef = interviewRef.collection("messages").doc();
        const message: Message = {
          id: messagesRef.id,
          senderUid: senderUid,
          content: "Proposed a new time for the interview.",
          type: "proposal",
          createdAt: now,
          metadata: {
            proposalId: messagesRef.id,
            proposedAt: proposedTimestamp,
            timeZone: timeZone,
          }
        };

        transaction.set(messagesRef, message);

        // Update Interview
        transaction.update(interviewRef, {
          updatedAt: now,
          lastMessage: {
            content: "📅 New date proposed",
            senderUid: senderUid,
            createdAt: now,
          },
        });
      });

      return { messageId: "sent" };

    } catch (error) {
       logger.error("Error proposing slot", error, loggerCtx);
      if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "Failed to propose slot");
    }
  }
);
