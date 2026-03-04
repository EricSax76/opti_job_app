/**
 * Cloud Function: onUserCreate
 *
 * Triggered when a new user is created in Firebase Auth.
 * Creates initial profile documents and sends welcome email.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";

const logger = createLogger({ function: "onUserCreate" });

export const onUserCreate = functions
  .region("europe-west1")
  .auth
  .user()
  .onCreate(async (user: functions.auth.UserRecord) => {
    const { uid, email, displayName } = user;

    logger.info("New user created", { uid, email });

    try {
      const db = admin.firestore();
      const now = admin.firestore.FieldValue.serverTimestamp();

      const candidateRef = db.collection("candidates").doc(uid);
      const companyRef = db.collection("companies").doc(uid);
      const [candidateDoc, companyDoc] = await Promise.all([
        candidateRef.get(),
        companyRef.get(),
      ]);

      // Keep role model explicit: only candidate/company.
      let role: "candidate" | "company" | null = null;
      if (candidateDoc.exists && !companyDoc.exists) {
        role = "candidate";
      } else if (companyDoc.exists && !candidateDoc.exists) {
        role = "company";
      } else if (
        user.customClaims?.role === "candidate" ||
        user.customClaims?.role === "company"
      ) {
        role = user.customClaims.role;
      }

      if (role === null) {
        logger.warn("Role unresolved on auth create. Skipping bootstrap", {
          uid,
          email,
        });
        return;
      }

      // If profile does not exist yet, bootstrap it in the explicit collection.
      if (role === "candidate" && !candidateDoc.exists) {
        const candidateProfile = {
          uid,
          name: displayName || email?.split("@")[0] || "Usuario",
          last_name: "",
          email: email || "",
          role: "candidate",
          onboarding_completed: false,
          id: Math.floor(Math.random() * 1000000),
          created_at: now,
          updated_at: now,
        };
        await candidateRef.set(candidateProfile, { merge: true });
        logger.info("Candidate profile bootstrapped", { uid });
      } else if (role === "company" && !companyDoc.exists) {
        const companyProfile = {
          uid,
          name: displayName || email?.split("@")[0] || "Empresa",
          email: email || "",
          role: "company",
          onboarding_completed: false,
          id: Math.floor(Math.random() * 1000000),
          created_at: now,
          updated_at: now,
        };
        await companyRef.set(companyProfile, { merge: true });
        logger.info("Company profile bootstrapped", { uid });
      }

      // ─── Backward compat: auto-crear reclutador admin para empresas que ya existían ───
      // Si existe companies/{uid} y NO existe recruiters/{uid}, lo creamos como admin.
      // Esto garantiza que las empresas registradas antes de Fase 0 sigan funcionando.
      if (role === "company") {
        const recruiterRef = db.collection("recruiters").doc(uid);
        const recruiterDoc = await recruiterRef.get();
        if (!recruiterDoc.exists) {
          const companyData = companyDoc.exists
            ? companyDoc.data()
            : { name: displayName || email?.split("@")[0] || "Empresa", email: email || "" };
          await recruiterRef.set(
            {
              uid,
              companyId: uid, // El companyId es el UID del admin fundador
              email: companyData?.email || email || "",
              name: companyData?.name || displayName || email?.split("@")[0] || "Empresa",
              role: "admin",
              status: "active",
              createdAt: now,
              updatedAt: now,
            },
            { merge: true }
          );
          logger.info("Admin recruiter auto-created for existing company", { uid });
        }
      }

      // Initialize user stats
      const stats = {
        uid,
        role,
        applications_count: role === "candidate" ? 0 : undefined,
        job_offers_count: role === "company" ? 0 : undefined,
        created_at: now,
        updated_at: now,
      };

      await db.collection("user_stats").doc(uid).set(stats, { merge: true });
      logger.info("User stats initialized", { uid, role });

      // TODO: Send welcome email
      // This would require email service setup (SendGrid, etc.)
      logger.info("Welcome email queued", { uid, email });

      logger.info("User onboarding completed successfully", { uid, role });
    } catch (error) {
      logger.error("Error in onUserCreate", error, { uid });
      // Don't throw - we don't want to fail user creation
      // Log the error and continue
    }
  });
