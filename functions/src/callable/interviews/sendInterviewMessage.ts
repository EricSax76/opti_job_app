/**
 * Callable Function: sendInterviewMessage
 *
 * Sends a message in an interview chat.
 * - Verifies participation
 * - Adds message to subcollection
 * - Updates interview unread counts and last message
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { ValidationError } from "../../utils/validation";
import { Interview, Message } from "../../types/models";

const logger = createLogger({ function: "sendInterviewMessage" });

const salaryHistoryPatterns = [
  /historial\s+salarial/i,
  /salario\s+(anterior|previo|actual)/i,
  /sueldo\s+(anterior|previo|actual)/i,
  /n[oó]mina\s+(anterior|previa|actual)/i,
  /cu[aá]nto\s+(cobrabas|cobraste|ganabas)/i,
  /previous\s+salary/i,
  /salary\s+history/i,
  /last\s+salary/i,
  /prior\s+salary/i,
  /current\s+salary/i,
  /payslip/i,
];

function containsProhibitedSalaryHistoryPrompt(content: string): boolean {
  const trimmed = content.trim();
  if (trimmed.length === 0) return false;

  // Pedir expectativa salarial sigue siendo legal.
  if (/expectativas?\s+salariales?/i.test(trimmed) ||
      /salary\s+expectations?/i.test(trimmed)) {
    return false;
  }

  return salaryHistoryPatterns.some((pattern) => pattern.test(trimmed));
}

export const sendInterviewMessage = functions.region("europe-west1").https.onCall(
  async (
    data: { interviewId: string; content: string; type?: Message["type"]; metadata?: Message["metadata"] },
    context: functions.https.CallableContext
  ): Promise<{ messageId: string }> => {
    // 1. Auth Check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }
    const senderUid = context.auth.uid;
    const { interviewId, content, type = "text", metadata } = data;
    const trimmedContent = (content ?? "").trim();

    if (!interviewId || !trimmedContent) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "interviewId and content are required"
      );
    }

    if (type === "text" && containsProhibitedSalaryHistoryPrompt(trimmedContent)) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "No se permite solicitar ni registrar historial salarial en procesos de selección."
      );
    }

    const db = admin.firestore();
    const loggerCtx = { interviewId, senderUid };
    let createdMessageId = "";

    try {
      await db.runTransaction(async (transaction) => {
        // 2. Fetch Interview
        const interviewRef = db.collection("interviews").doc(interviewId);
        const interviewDoc = await transaction.get(interviewRef);

        if (!interviewDoc.exists) {
          throw new ValidationError("Interview not found");
        }
        const interview = interviewDoc.data() as Interview;

        // Verify Participant
        if (!interview.participants.includes(senderUid)) {
           throw new functions.https.HttpsError(
            "permission-denied",
            "User is not a participant in this interview"
          );
        }

        // 3. Create Message Logic
        const now = admin.firestore.Timestamp.now();
        const messagesRef = interviewRef.collection("messages").doc();
        createdMessageId = messagesRef.id;
        const message: Message = {
          id: messagesRef.id,
          senderUid: senderUid,
          content: trimmedContent,
          type: type,
          createdAt: now,
        };

        if (metadata) {
          message.metadata = metadata;
        }

        transaction.set(messagesRef, message);

        // 4. Update Interview Metadata (Unread Counts & Last Message)
        const updates: Record<string, any> = {
          updatedAt: now,
          lastMessage: {
            content: type === 'text' ? message.content : `[${type}]`,
            senderUid: senderUid,
            createdAt: now,
          },
        };

        // Increment unread count for OTHER participants
        const otherParticipants = interview.participants.filter(p => p !== senderUid);
        for (const uid of otherParticipants) {
          updates[`unreadCounts.${uid}`] = admin.firestore.FieldValue.increment(1);
        }

        transaction.update(interviewRef, updates);
      });

      return { messageId: createdMessageId || "sent" };

    } catch (error) {
      logger.error("Error sending message", error, loggerCtx);
       if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "Failed to send message");
    }
  }
);
