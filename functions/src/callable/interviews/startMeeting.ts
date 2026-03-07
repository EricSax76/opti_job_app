/**
 * Callable Function: startMeeting
 *
 * Starts an interview meeting.
 * - Verifies interview participation
 * - Rejects finished interviews
 * - Stores meeting link on interview
 * - Adds a system message + lastMessage
 * - Writes an audit log entry
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { ValidationError } from "../../utils/validation";
import { Interview, Message } from "../../types/models";
import { buildAuditLogRecord } from "../../utils/auditLog";

const logger = createLogger({ function: "startMeeting" });

function readNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function normalizeMeetingLink(rawLink: unknown): string {
  const meetingLink = readNonEmptyString(rawLink);
  if (!meetingLink) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "meetingLink is required",
    );
  }

  if (meetingLink.length > 2048) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "meetingLink is too long",
    );
  }

  let parsed: URL;
  try {
    parsed = new URL(meetingLink);
  } catch {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "meetingLink must be a valid URL",
    );
  }

  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "meetingLink protocol must be http or https",
    );
  }

  return meetingLink;
}

function resolveActorRole(interview: Interview, actorUid: string): string {
  if (interview.companyUid === actorUid) return "company";
  if (interview.candidateUid === actorUid) return "candidate";
  return "participant";
}

function extractMeetingHost(meetingLink: string): string | null {
  try {
    const host = new URL(meetingLink).host.trim();
    return host.length > 0 ? host : null;
  } catch {
    return null;
  }
}

export const startMeeting = functions.region("europe-west1").https.onCall(
  async (
    data: { interviewId: string; meetingLink: string },
    context: functions.https.CallableContext,
  ): Promise<void> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated",
      );
    }

    const actorUid = context.auth.uid;
    const interviewId = readNonEmptyString(data?.interviewId);
    const meetingLink = normalizeMeetingLink(data?.meetingLink);

    if (!interviewId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "interviewId is required",
      );
    }

    const db = admin.firestore();
    const loggerCtx = {
      interviewId,
      actorUid,
      meetingHost: extractMeetingHost(meetingLink),
    };

    try {
      await db.runTransaction(async (transaction) => {
        const interviewRef = db.collection("interviews").doc(interviewId);
        const interviewDoc = await transaction.get(interviewRef);

        if (!interviewDoc.exists) {
          throw new ValidationError("Interview not found");
        }
        const interview = interviewDoc.data() as Interview;

        if (!interview.participants.includes(actorUid)) {
          throw new functions.https.HttpsError(
            "permission-denied",
            "User is not a participant in this interview",
          );
        }

        if (interview.status === "cancelled" || interview.status === "completed") {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Interview is already finished",
          );
        }

        const now = admin.firestore.Timestamp.now();
        const messageRef = interviewRef.collection("messages").doc();
        const systemMessage: Message = {
          id: messageRef.id,
          senderUid: "system",
          content: `Inició una videollamada. Únete aquí: ${meetingLink}`,
          type: "system",
          createdAt: now,
        };

        transaction.set(messageRef, systemMessage);
        transaction.update(interviewRef, {
          meetingLink,
          updatedAt: now,
          lastMessage: {
            content: "Videollamada iniciada",
            senderUid: "system",
            createdAt: now,
          },
        });

        const auditRef = db.collection("auditLogs").doc();
        transaction.set(
          auditRef,
          buildAuditLogRecord(
            {
              action: "interview.startMeeting",
              actorUid,
              actorRole: resolveActorRole(interview, actorUid),
              targetType: "interview",
              targetId: interviewId,
              companyId: interview.companyUid ?? null,
              metadata: {
                messageId: messageRef.id,
                meetingHost: extractMeetingHost(meetingLink),
                statusBefore: interview.status,
              },
            },
            now,
          ),
        );
      });

      logger.info("Meeting started successfully", loggerCtx);
    } catch (error) {
      logger.error("Error starting meeting", error, loggerCtx);
      if (error instanceof ValidationError) {
        throw new functions.https.HttpsError("invalid-argument", error.message);
      }
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", "Failed to start meeting");
    }
  },
);
