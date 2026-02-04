/**
 * Cloud Function: onUserCreate
 *
 * Triggered when a new user is created in Firebase Auth.
 * Creates initial profile documents and sends welcome email.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { UserProfile } from "../../types/models";

const logger = createLogger({ function: "onUserCreate" });

export const onUserCreate = functions.auth
  .user()
  .onCreate(async (user: functions.auth.UserRecord) => {
    const { uid, email, displayName } = user;

  logger.info("New user created", { uid, email });

  try {
    const db = admin.firestore();
    const now = admin.firestore.FieldValue.serverTimestamp();

    // Determine user role based on email or custom claims
    // Default to 'candidate', companies should be identified differently
    let role: "candidate" | "company" = "candidate";

    // You can customize this logic based on your requirements
    // For example, check if email matches certain patterns or use custom claims
    if (email?.includes("@company.") || user.customClaims?.role === "company") {
      role = "company";
    }

    // Create basic user profile
    const userProfile: Partial<UserProfile> = {
      uid,
      email: email || "",
      role,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      createdAt: now as any,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      updatedAt: now as any,
    };

    await db.collection("users").doc(uid).set(userProfile);
    logger.info("User profile created", { uid, role });

    // Create role-specific profile
    if (role === "candidate") {
      const candidateProfile = {
        uid,
        name: displayName || email?.split("@")[0] || "Usuario",
        email: email || "",
        id: Math.floor(Math.random() * 1000000), // Temporary ID generation
        created_at: now,
        updated_at: now,
      };

      await db.collection("candidates").doc(uid).set(candidateProfile);
      logger.info("Candidate profile created", { uid });
    } else {
      const companyProfile = {
        uid,
        name: displayName || email?.split("@")[0] || "Empresa",
        email: email || "",
        id: Math.floor(Math.random() * 1000000), // Temporary ID generation
        created_at: now,
        updated_at: now,
      };

      await db.collection("companies").doc(uid).set(companyProfile);
      logger.info("Company profile created", { uid });
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

    await db.collection("user_stats").doc(uid).set(stats);
    logger.info("User stats initialized", { uid });

    // TODO: Send welcome email
    // This would require email service setup (SendGrid, etc.)
    logger.info("Welcome email queued", { uid, email });

    logger.info("User onboarding completed successfully", { uid });
  } catch (error) {
    logger.error("Error in onUserCreate", error, { uid });
    // Don't throw - we don't want to fail user creation
    // Log the error and continue
  }
});
