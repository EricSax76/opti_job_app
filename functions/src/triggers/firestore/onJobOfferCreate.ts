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

const SALARY_GAP_THRESHOLD = 0.05;

function toNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function normalizeRoleKey(title: string, category?: string): string {
  const source = `${title ?? ""} ${category ?? ""}`.trim().toLowerCase();
  return source
    .replace(/[^\w\s-]/g, "")
    .replace(/\s+/g, "_")
    .slice(0, 80);
}

function salaryMidpoint(offer: JobOffer): number | null {
  const min = toNumber(offer.salary_min);
  const max = toNumber(offer.salary_max);
  if (min == null && max == null) return null;
  if (min != null && max != null) return (min + max) / 2;
  return min ?? max;
}

async function computeSalaryGapAudit(
  db: FirebaseFirestore.Firestore,
  offerId: string,
  offer: JobOffer,
): Promise<{
  shouldBlock: boolean;
  audit: Record<string, unknown>;
} | null> {
  const companyUid = String(offer.company_uid ?? "").trim();
  if (!companyUid) return null;

  const roleKey = normalizeRoleKey(offer.title, offer.job_category);
  if (!roleKey) return null;

  const benchmarkSnapshot = await db
    .collection("salaryBenchmarks")
    .where("companyId", "==", companyUid)
    .where("roleKey", "==", roleKey)
    .get();

  if (benchmarkSnapshot.empty) {
    return {
      shouldBlock: false,
      audit: {
        checkedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "not_enough_data",
        reason: "No salary benchmarks found for this role.",
        threshold: SALARY_GAP_THRESHOLD,
        roleKey,
      },
    };
  }

  let maleAvg: number | null = null;
  let femaleAvg: number | null = null;
  let nonBinaryAvg: number | null = null;
  let totalSamples = 0;
  for (const doc of benchmarkSnapshot.docs) {
    const row = doc.data();
    const gender = String(row.gender ?? "").trim();
    const avg = toNumber(row.averageSalary);
    const sampleSize = toNumber(row.sampleSize) ?? 0;
    totalSamples += Math.max(0, Math.trunc(sampleSize));
    if (avg == null) continue;
    if (gender === "male") maleAvg = avg;
    if (gender === "female") femaleAvg = avg;
    if (gender === "non_binary") nonBinaryAvg = avg;
  }

  if (maleAvg == null || femaleAvg == null) {
    return {
      shouldBlock: false,
      audit: {
        checkedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "not_enough_gender_data",
        reason: "Benchmarks require male and female averages to compute mandatory gap checks.",
        threshold: SALARY_GAP_THRESHOLD,
        roleKey,
        totalSamples,
      },
    };
  }

  const baseline = Math.max(Math.abs(maleAvg), Math.abs(femaleAvg), 1);
  const gapRatio = Math.abs(maleAvg - femaleAvg) / baseline;
  const gapPercent = Number((gapRatio * 100).toFixed(2));
  const offerMidpoint = salaryMidpoint(offer);
  const shouldBlock = gapRatio > SALARY_GAP_THRESHOLD;

  const audit: Record<string, unknown> = {
    checkedAt: admin.firestore.FieldValue.serverTimestamp(),
    threshold: SALARY_GAP_THRESHOLD,
    status: shouldBlock ? "blocked" : "ok",
    roleKey,
    maleAverageSalary: maleAvg,
    femaleAverageSalary: femaleAvg,
    nonBinaryAverageSalary: nonBinaryAvg,
    gapPercent,
    offerMidpointSalary: offerMidpoint,
    benchmarkSamples: totalSamples,
  };

  if (shouldBlock) {
    await db.collection("salaryGapAlerts").add({
      companyId: companyUid,
      offerId,
      roleKey,
      gapPercent,
      threshold: SALARY_GAP_THRESHOLD * 100,
      status: "open",
      message:
        "Detected gender pay gap above 5% for the same role. Objective justification is required before publication.",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return { shouldBlock, audit };
}

export const onJobOfferCreate = functions
  .region("europe-west1")
  .firestore
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
      const updates: Record<string, unknown> = {};

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

      // Salary gap compliance (EU 2023/970 transposition): if gap > 5%
      // for same role and company, block publication until objective justification.
      const salaryGapAudit = await computeSalaryGapAudit(db, offerId, jobOffer);
      if (salaryGapAudit != null) {
        updates.salary_gap_audit = salaryGapAudit.audit;
        if (salaryGapAudit.shouldBlock) {
          updates.status = "blocked_pending_salary_justification";
          updates.salary_gap_justification_required = true;
          updates.salary_gap_justification_status = "pending";
          updates.publication_block_reason = "salary_gap_above_5_percent";
        }
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
