/**
 * Cloud Function: onApplicationCreate
 *
 * Triggered when a new application is created.
 * Handles post-creation side effects asynchronously:
 *   - Increments counters (offer + user stats)
 *   - Creates activity timeline entry
 *   - Sends legal acknowledgment (notification + email + audit log)
 *
 * Validation (offer status, duplicates) is handled upstream by the
 * submitApplication callable — this trigger focuses on side effects.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Application, JobOffer } from "../../types/models";

const logger = createLogger({ function: "onApplicationCreate" });

const LEGAL_INFO_CLAUSE =
  "Tus datos se tratarán para gestionar la candidatura y evaluar tu encaje con la vacante. " +
  "Base jurídica: ejecución de medidas precontractuales y, en su caso, consentimiento. " +
  "Puedes ejercer ARSULIPO y solicitar explicación humana de decisiones de IA desde el portal de privacidad.";

export const onApplicationCreate = functions
  .runWith({ memory: "512MB", timeoutSeconds: 120 })
  .region("europe-west1")
  .firestore.document("applications/{applicationId}")
  .onCreate(async (snapshot, context) => {
    const { applicationId } = context.params;
    const application = snapshot.data() as Application;
    const raw = snapshot.data() as Record<string, unknown>;
    const candidateUid =
      application.candidate_uid || String(raw.candidateId ?? "");
    const jobOfferId =
      application.job_offer_id || String(raw.jobOfferId ?? "");
    const companyUid =
      application.company_uid || String(raw.companyUid ?? "") || null;

    logger.info("New application created", {
      applicationId,
      jobOfferId,
      candidateUid,
    });

    try {
      const db = admin.firestore();
      const offerRef = db.collection("jobOffers").doc(jobOfferId);

      // Phase 1: parallel reads — offer (for title) + user stats
      const [offerDoc, statsDoc] = await Promise.all([
        offerRef.get(),
        db.collection("user_stats").doc(candidateUid).get(),
      ]);

      const jobOffer = offerDoc.exists
        ? (offerDoc.data() as JobOffer)
        : null;

      if (!offerDoc.exists) {
        logger.error("Job offer not found for side effects", null, {
          applicationId,
          jobOfferId,
        });
      }

      // Phase 2: single batch with all writes
      const now = admin.firestore.FieldValue.serverTimestamp();
      const batch = db.batch();

      // 1. Increment application counter on job offer
      if (offerDoc.exists) {
        batch.update(offerRef, {
          applications_count: admin.firestore.FieldValue.increment(1),
          updated_at: now,
        });
      }

      // 2. Update user stats
      if (statsDoc.exists) {
        batch.update(statsDoc.ref, {
          applications_count: admin.firestore.FieldValue.increment(1),
          last_application_at: now,
          updated_at: now,
        });
      }

      // 3. Create activity timeline entry
      batch.set(db.collection("activities").doc(), {
        type: "application_created",
        user_uid: candidateUid,
        application_id: applicationId,
        job_offer_id: jobOfferId,
        company_uid: companyUid,
        created_at: now,
      });

      // 4. Legal acknowledgment — notification (in-app)
      const candidateEmail =
        application.candidate_email || String(raw.candidateEmail ?? "");
      const legalAckSubject = "Hemos recibido tu candidatura";
      const legalAckBody = [
        `Solicitud: ${applicationId}`,
        `Oferta: ${jobOffer?.title ?? jobOfferId}`,
        "Acuse de recibo legal de candidatura:",
        LEGAL_INFO_CLAUSE,
      ].join("\n");

      batch.set(db.collection("notifications").doc(), {
        type: "application_received_legal_ack",
        channel: "in_app",
        audience: "candidate",
        userUid: candidateUid,
        companyUid: companyUid,
        applicationId,
        jobOfferId,
        title: legalAckSubject,
        message: legalAckBody,
        legalInfoClause: LEGAL_INFO_CLAUSE,
        read: false,
        createdAt: now,
        updatedAt: now,
      });

      // 5. Legal acknowledgment — email queue
      if (candidateEmail) {
        batch.set(db.collection("emailQueue").doc(), {
          to: candidateEmail,
          template: "application_received_legal_ack",
          subject: legalAckSubject,
          text: legalAckBody,
          candidateUid,
          companyUid: companyUid,
          applicationId,
          jobOfferId,
          legalInfoClause: LEGAL_INFO_CLAUSE,
          status: "queued",
          createdAt: now,
          updatedAt: now,
        });
      }

      // 6. Audit log — legal ack sent
      batch.set(db.collection("auditLogs").doc(), {
        action: "application_legal_ack_sent",
        actorUid: "system",
        actorRole: "system",
        targetType: "application",
        targetId: applicationId,
        companyId: companyUid,
        metadata: {
          candidateUid,
          jobOfferId,
          notificationChannel: "in_app",
          emailQueued: Boolean(candidateEmail),
          legalInfoClauseVersion: "2026-03",
        },
        timestamp: now,
      });

      await batch.commit();

      logger.info("Application side effects completed", {
        applicationId,
        writes: [
          offerDoc.exists && "offer_counter",
          statsDoc.exists && "user_stats",
          "activity",
          "notification",
          candidateEmail && "email_queue",
          "audit_log",
        ].filter(Boolean),
      });
    } catch (error) {
      logger.error("Error processing application side effects", error, {
        applicationId,
      });
      try {
        await snapshot.ref.update({
          processing_error:
            error instanceof Error ? error.message : String(error),
        });
      } catch (updateError) {
        logger.error("Failed to update application with error", updateError);
      }
    }
  });
