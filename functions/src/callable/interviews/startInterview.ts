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
import {
  AiConsentScope,
  grantedAtMillis,
  hasValidAiConsentRecord,
} from "../../utils/aiConsent";

const logger = createLogger({ function: "startInterview" });

function pickNonEmptyString(...values: unknown[]): string | undefined {
  for (const value of values) {
    if (value === null || value === undefined) continue;
    const normalized = String(value).trim();
    if (normalized.length > 0) return normalized;
  }
  return undefined;
}

async function hasValidAiConsent({
  transaction,
  db,
  candidateUid,
  companyUid,
  requiredScope,
}: {
  transaction: FirebaseFirestore.Transaction;
  db: FirebaseFirestore.Firestore;
  candidateUid: string;
  companyUid: string;
  requiredScope: AiConsentScope;
}): Promise<boolean> {
  const snapshot = await transaction.get(
    db
      .collection("consentRecords")
      .where("candidateUid", "==", candidateUid)
      .limit(50),
  );
  if (snapshot.empty) return false;

  const now = new Date();
  const records = snapshot.docs
    .map((doc) => doc.data() as Record<string, unknown>)
    .sort((a, b) => grantedAtMillis(b) - grantedAtMillis(a));

  return records.some((record) =>
    hasValidAiConsentRecord({
      record,
      companyId: companyUid,
      requiredScope,
      now,
    }),
  );
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
    const actorUid = context.auth.uid;
    const { applicationId } = data;

    if (!applicationId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "applicationId is required"
      );
    }

    const db = admin.firestore();
    const loggerCtx = { applicationId, actorUid };
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

        // Check requester ownership / RBAC:
        // - Company main account can start interviews.
        // - Recruiters with role admin|recruiter in the same company can start interviews.
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const offerOwner = offer.company_uid || (offer as any).companyUid || (offer as any).owner_uid;
        if (!offerOwner) {
          throw new ValidationError("Job offer is missing company owner");
        }

        if (actorUid !== offerOwner) {
          const recruiterRef = db.collection("recruiters").doc(actorUid);
          const recruiterDoc = await transaction.get(recruiterRef);
          if (!recruiterDoc.exists) {
            throw new functions.https.HttpsError(
              "permission-denied",
              "Only company owner or recruiter with interview permissions can start an interview"
            );
          }
          const recruiter = recruiterDoc.data() as Record<string, unknown>;
          const role = String(recruiter.role ?? "");
          const status = String(recruiter.status ?? "");
          const recruiterCompanyId = String(recruiter.companyId ?? "");
          const canStartInterview = ["admin", "recruiter"].includes(role);
          if (
            recruiterCompanyId !== offerOwner ||
            status !== "active" ||
            !canStartInterview
          ) {
            throw new functions.https.HttpsError(
              "permission-denied",
              "Your recruiter role cannot start interviews for this company"
            );
          }
        }

        // 3. Check for existing interview (Idempotency)
        const interviewRef = db.collection("interviews").doc(applicationId);
        const interviewDoc = await transaction.get(interviewRef);

        if (interviewDoc.exists) {
          logger.info("Interview already exists", loggerCtx);
          return; // Already created, just return (idempotent)
        }

        const hasConsent = await hasValidAiConsent({
          transaction,
          db,
          candidateUid,
          companyUid: offerOwner,
          requiredScope: "ai_interview",
        });
        if (!hasConsent) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "No existe consentimiento IA vigente del candidato para iniciar entrevista.",
          );
        }

        // 4. Create Interview Document
        const now = admin.firestore.Timestamp.now();
        const participants = actorUid === offerOwner
          ? [offerOwner, candidateUid]
          : [offerOwner, candidateUid, actorUid];

        const interview: Interview = {
          id: applicationId,
          applicationId: applicationId,
          jobOfferId: jobOfferId,
          companyUid: offerOwner,
          candidateUid: candidateUid,
          participants,
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
          senderUid: actorUid,
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
