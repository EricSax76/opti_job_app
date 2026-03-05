/**
 * Cloud Function: onUserDelete
 *
 * Triggered when a user is deleted from Firebase Auth.
 * Cleans up user data and archives applications for GDPR compliance.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";

const logger = createLogger({ function: "onUserDelete" });

export const onUserDelete = functions
  .region("europe-west1")
  .auth
  .user()
  .onDelete(async (user: functions.auth.UserRecord) => {
    const { uid, email } = user;

    logger.info("User deleted, starting cleanup", { uid, email });

    try {
      const db = admin.firestore();
      const storage = admin.storage().bucket();
      const batch = db.batch();

      // Delete candidate or company profile
      const candidateRef = db.collection("candidates").doc(uid);
      const companyRef = db.collection("companies").doc(uid);
      // Delete recruiter profile (Fase 0 RBAC)
      const recruiterRef = db.collection("recruiters").doc(uid);

      const [candidateDoc, companyDoc] = await Promise.all([
        candidateRef.get(),
        companyRef.get(),
      ]);

      if (candidateDoc.exists) {
        batch.delete(candidateRef);
        logger.info("Candidate profile marked for deletion", { uid });
      }

      if (companyDoc.exists) {
        batch.delete(companyRef);
        logger.info("Company profile marked for deletion", { uid });
      }

      // Limpieza del reclutador (Fase 0 RBAC)
      // Marcamos status=disabled en lugar de borrar (preservar auditoría RGPD)
      const recruiterDoc = await recruiterRef.get();
      if (recruiterDoc.exists) {
        batch.update(recruiterRef, {
          status: "disabled",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info("Recruiter marked as disabled on user delete", { uid });
      }

      // Delete user stats
      const statsRef = db.collection("user_stats").doc(uid);
      batch.delete(statsRef);
      const userRef = db.collection("users").doc(uid);
      batch.delete(userRef);

      // Archive applications instead of deleting (for audit trail)
      const applicationsSnapshot = await db
        .collection("applications")
        .where("candidate_uid", "==", uid)
        .get();

      if (!applicationsSnapshot.empty) {
        const archiveBatch = db.batch();
        applicationsSnapshot.docs.forEach((doc) => {
          const archiveRef = db.collection("archived_applications").doc(doc.id);
          archiveBatch.set(archiveRef, {
            ...doc.data(),
            archived_at: admin.firestore.FieldValue.serverTimestamp(),
            archived_reason: "user_deleted",
          });
          archiveBatch.delete(doc.ref);
        });
        await archiveBatch.commit();
        logger.info("Applications archived", {
          uid,
          count: applicationsSnapshot.size,
        });
      }

      // Delete curriculum documents
      const curriculumSnapshot = await db
        .collection("curriculum")
        .where("uid", "==", uid)
        .get();

      if (!curriculumSnapshot.empty) {
        const cvBatch = db.batch();
        curriculumSnapshot.docs.forEach((doc) => {
          cvBatch.delete(doc.ref);
        });
        await cvBatch.commit();
        logger.info("Curriculum documents deleted", {
          uid,
          count: curriculumSnapshot.size,
        });
      }

      // If company, handle job offers
      if (companyDoc.exists) {
        const offersSnapshot = await db
          .collection("jobOffers")
          .where("company_uid", "==", uid)
          .get();

        if (!offersSnapshot.empty) {
          const offersBatch = db.batch();
          offersSnapshot.docs.forEach((doc) => {
            // Mark as deleted instead of removing (preserve application history)
            offersBatch.update(doc.ref, {
              status: "deleted",
              deleted_at: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
          await offersBatch.commit();
          logger.info("Job offers marked as deleted", {
            uid,
            count: offersSnapshot.size,
          });
        }
      }

      // Commit main batch
      await batch.commit();

      // Clean up Storage files (candidate/company namespaces only).
      try {
        const storagePrefixes = [`candidates/${uid}/`, `companies/${uid}/`];
        let deletedCount = 0;

        for (const prefix of storagePrefixes) {
          const [files] = await storage.getFiles({ prefix });
          if (files.length === 0) continue;
          await Promise.all(files.map((file) => file.delete()));
          deletedCount += files.length;
        }

        if (deletedCount > 0) {
          logger.info("Storage files deleted", {
            uid,
            count: deletedCount,
          });
        }
      } catch (storageError) {
        logger.error("Error deleting storage files", storageError);
        // Continue even if storage cleanup fails
      }

      logger.info("User cleanup completed successfully", { uid });
    } catch (error) {
      logger.error("Error in onUserDelete", error);
      // Don't throw - log error but don't fail the deletion
    }
  });
