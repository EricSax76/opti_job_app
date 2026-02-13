/**
 * Callable Function: respondInterviewSlot
 *
 * Responds to an interview proposal (Accept or Reject).
 * - If Accepted: Updates interview status to "scheduled" and sets scheduledAt.
 * - If Rejected: Adds rejection message.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { ValidationError } from "../../utils/validation";
import { Interview, Message } from "../../types/models";

const logger = createLogger({ function: "respondInterviewSlot" });

export const respondInterviewSlot = functions.https.onCall(
  async (
    data: { interviewId: string; proposalId: string; response: "accept" | "reject" },
    context: functions.https.CallableContext
  ): Promise<{ messageId: string }> => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const senderUid = context.auth.uid;
    const { interviewId, proposalId, response } = data;

    if (!interviewId || !proposalId || !["accept", "reject"].includes(response)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid arguments");
    }

    const db = admin.firestore();
    const loggerCtx = { interviewId, senderUid, response };

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

        // Fetch original proposal message to verify details
        const proposalRef = interviewRef.collection("messages").doc(proposalId);
        const proposalDoc = await transaction.get(proposalRef);

        if (!proposalDoc.exists) {
           throw new ValidationError("Proposal not found");
        }
        const proposal = proposalDoc.data() as Message;

        if (proposal.type !== 'proposal' || !proposal.metadata?.proposedAt) {
             throw new ValidationError("Invalid proposal message");
        }

        const now = admin.firestore.Timestamp.now();
        const messagesRef = interviewRef.collection("messages").doc();
        let message: Message;
        let interviewUpdates: any = { updatedAt: now };

        if (response === 'accept') {
          message = {
            id: messagesRef.id,
            senderUid: senderUid,
            content: "Accepted the interview time.",
            type: "acceptance",
            createdAt: now,
            metadata: {
              proposalId: proposalId,
              proposedAt: proposal.metadata.proposedAt,
              timeZone: proposal.metadata.timeZone,
            }
          };
          
          interviewUpdates.status = "scheduled";
          interviewUpdates.scheduledAt = proposal.metadata.proposedAt;
          interviewUpdates.timeZone = proposal.metadata.timeZone;
          interviewUpdates.lastMessage = {
             content: "✅ Interview Scheduled",
             senderUid: senderUid,
             createdAt: now,
          };

        } else {
             message = {
            id: messagesRef.id,
            senderUid: senderUid,
            content: "Declined the proposed time.",
            type: "rejection",
            createdAt: now,
             metadata: {
              proposalId: proposalId,
             }
          };
           interviewUpdates.lastMessage = {
             content: "❌ Time Declined",
             senderUid: senderUid,
             createdAt: now,
          };
        }

        transaction.set(messagesRef, message);
        transaction.update(interviewRef, interviewUpdates);
      });

      return { messageId: "sent" };

    } catch (error) {
       logger.error("Error responding to slot", error, loggerCtx);
      if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "Failed to respond");
    }
  }
);
