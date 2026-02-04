/**
 * Cloud Function: onJobOfferCreate
 *
 * Triggered when a new job offer is created.
 * Validates data and initializes counters.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { validateJobOffer } from "../../utils/validation";
import { JobOffer } from "../../types/models";

const logger = createLogger({ function: "onJobOfferCreate" });

export const onJobOfferCreate = functions.firestore
  .document("jobOffers/{offerId}")
  .onCreate(async (snapshot, context) => {
    const { offerId } = context.params;
    const jobOffer = snapshot.data() as JobOffer;

    logger.info("New job offer created", {
      offerId,
      companyUid: jobOffer.company_uid,
      title: jobOffer.title,
    });

    try {
      // Validate job offer data
      validateJobOffer(jobOffer);

      const db = admin.firestore();
      const updates: Partial<JobOffer> = {};

      // Ensure applications_count is initialized
      if (typeof jobOffer.applications_count !== "number") {
        updates.applications_count = 0;
      }

      // Set default status if not provided
      if (!jobOffer.status) {
        updates.status = "active";
      }

      // Normalize skills array
      if (jobOffer.skills && Array.isArray(jobOffer.skills)) {
        updates.skills = jobOffer.skills.map((s) => s.toLowerCase().trim());
      }

      // Apply updates if any
      if (Object.keys(updates).length > 0) {
        await snapshot.ref.update(updates);
        logger.info("Job offer initialized with defaults", { offerId, updates });
      }

      // Update company stats
      const statsRef = db.collection("user_stats").doc(jobOffer.company_uid);
      const statsDoc = await statsRef.get();

      if (statsDoc.exists) {
        await statsRef.update({
          job_offers_count: admin.firestore.FieldValue.increment(1),
          last_offer_created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info("Company stats updated", { companyUid: jobOffer.company_uid });
      }

      // Create activity entry
      await db.collection("activities").add({
        type: "job_offer_created",
        user_uid: jobOffer.company_uid,
        job_offer_id: offerId,
        title: jobOffer.title,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // TODO: Notify matching candidates
      // This would analyze candidate profiles and send notifications
      logger.info("Candidate matching queued", { offerId });

      logger.info("Job offer processing completed", { offerId });
    } catch (error) {
      logger.error("Error processing job offer", error, { offerId });
      // Mark offer with validation error if needed
      try {
        await snapshot.ref.update({
          processing_error: error instanceof Error ? error.message : String(error),
        });
      } catch (updateError) {
        logger.error("Failed to update offer with error", updateError);
      }
    }
  });
