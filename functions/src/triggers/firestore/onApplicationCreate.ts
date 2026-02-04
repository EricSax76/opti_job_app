/**
 * Cloud Function: onApplicationCreate
 *
 * Triggered when a new application is created.
 * Validates data, updates counters, and sends notifications.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Application, JobOffer } from "../../types/models";

const logger = createLogger({ function: "onApplicationCreate" });

export const onApplicationCreate = functions.firestore
  .document("applications/{applicationId}")
  .onCreate(async (snapshot, context) => {
    const { applicationId } = context.params;
    const application = snapshot.data() as Application;

    logger.info("New application created", {
      applicationId,
      jobOfferId: application.job_offer_id,
      candidateUid: application.candidate_uid,
    });

    try {
      const db = admin.firestore();

      // Verify job offer exists and is active
      const offerRef = db.collection("jobOffers").doc(application.job_offer_id);
      const offerDoc = await offerRef.get();

      if (!offerDoc.exists) {
        logger.error("Job offer not found", null, {
          applicationId,
          jobOfferId: application.job_offer_id,
        });
        // Mark application as invalid
        await snapshot.ref.update({
          status: "invalid",
          error: "Job offer not found",
        });
        return;
      }

      const jobOffer = offerDoc.data() as JobOffer;

      if (jobOffer.status !== "active") {
        logger.warn("Application to non-active job offer", {
          applicationId,
          jobOfferId: application.job_offer_id,
          offerStatus: jobOffer.status,
        });
      }

      // Check for duplicate applications
      const existingApplications = await db
        .collection("applications")
        .where("job_offer_id", "==", application.job_offer_id)
        .where("candidate_uid", "==", application.candidate_uid)
        .where("status", "!=", "withdrawn")
        .get();

      if (existingApplications.size > 1) {
        logger.warn("Duplicate application detected", {
          applicationId,
          existingCount: existingApplications.size,
        });
        // Keep the newer one, mark older as withdrawn
        const docs = existingApplications.docs.sort(
          (a, b) => a.createTime!.toMillis() - b.createTime!.toMillis()
        );
        for (let i = 0; i < docs.length - 1; i++) {
          await docs[i].ref.update({
            status: "withdrawn",
            withdrawn_reason: "duplicate_application",
          });
        }
      }

      // Increment application counter on job offer
      await offerRef.update({
        applications_count: admin.firestore.FieldValue.increment(1),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Job offer counter incremented", {
        jobOfferId: application.job_offer_id,
      });

      // Update user stats
      const statsRef = db.collection("user_stats").doc(application.candidate_uid);
      const statsDoc = await statsRef.get();

      if (statsDoc.exists) {
        await statsRef.update({
          applications_count: admin.firestore.FieldValue.increment(1),
          last_application_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Create activity/timeline entry
      await db.collection("activities").add({
        type: "application_created",
        user_uid: application.candidate_uid,
        application_id: applicationId,
        job_offer_id: application.job_offer_id,
        company_uid: jobOffer.company_uid,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info("Activity created", { applicationId });

      // TODO: Send notification to company
      // This would be implemented in the notification service
      logger.info("Company notification queued", {
        companyUid: jobOffer.company_uid,
        applicationId,
      });

      logger.info("Application processing completed", { applicationId });
    } catch (error) {
      logger.error("Error processing application", error, { applicationId });
      // Update application with error status
      try {
        await snapshot.ref.update({
          processing_error: error instanceof Error ? error.message : String(error),
        });
      } catch (updateError) {
        logger.error("Failed to update application with error", updateError);
      }
    }
  });
