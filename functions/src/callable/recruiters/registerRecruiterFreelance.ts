/**
 * Callable: registerRecruiterFreelance
 *
 * Permite que un usuario autenticado cree su perfil de recruiter autónomo
 * (sin empresa asignada) para poder iniciar sesión en el módulo recruiter.
 *
 * El flujo de invitación por empresa se mantiene y puede vincular después
 * a este recruiter autónomo mediante `acceptInvitation`.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Recruiter } from "../../types/models";
import { syncRecruiterClaimsFromFirestore } from "../../utils/recruiterClaims";

const logger = createLogger({ function: "registerRecruiterFreelance" });

interface RegisterRecruiterFreelanceRequest {
  name?: string;
}

function normalizeName(rawName: string | undefined, fallbackEmail: string): string {
  const trimmed = typeof rawName === "string" ? rawName.trim() : "";
  if (trimmed.length > 0) return trimmed;
  const emailPrefix = fallbackEmail.split("@")[0]?.trim();
  if (emailPrefix && emailPrefix.length > 0) return emailPrefix;
  return "Recruiter";
}

export const registerRecruiterFreelance = functions
  .region("europe-west1")
  .https.onCall(async (data: RegisterRecruiterFreelanceRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para completar el alta de recruiter."
      );
    }

    const uid = context.auth.uid;
    const email = String(context.auth.token.email ?? "").trim().toLowerCase();
    if (!email) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Tu cuenta no tiene un email válido."
      );
    }

    const payload = (data ?? {}) as RegisterRecruiterFreelanceRequest;
    const resolvedName = normalizeName(payload.name, email);
    const db = admin.firestore();
    const now = admin.firestore.FieldValue.serverTimestamp();

    await db.runTransaction(async (transaction) => {
      const recruiterRef = db.collection("recruiters").doc(uid);
      const usersRef = db.collection("users").doc(uid);

      const [recruiterDoc, usersDoc] = await Promise.all([
        transaction.get(recruiterRef),
        transaction.get(usersRef),
      ]);

      if (recruiterDoc.exists) {
        const existing = recruiterDoc.data() as Recruiter;
        const existingCompanyId = String(existing.companyId ?? "").trim();
        if (existingCompanyId.length > 0) {
          throw new functions.https.HttpsError(
            "failed-precondition",
            "Ya tienes un perfil recruiter asociado a una empresa."
          );
        }

        transaction.set(
          recruiterRef,
          {
            email,
            name: resolvedName,
            role: existing.role ?? "recruiter",
            status: "active",
            updatedAt: now,
          },
          { merge: true }
        );
      } else {
        transaction.set(recruiterRef, {
          uid,
          companyId: "",
          email,
          name: resolvedName,
          role: "recruiter",
          status: "active",
          acceptedAt: now,
          createdAt: now,
          updatedAt: now,
        });
      }

      const usersData = usersDoc.exists ? usersDoc.data() ?? {} : {};
      const existingRolesRaw = Array.isArray(usersData.roles) ? usersData.roles : [];
      const roleSet = new Set<string>();
      for (const role of existingRolesRaw) {
        const parsed = String(role ?? "").trim().toLowerCase();
        if (parsed.length > 0) {
          roleSet.add(parsed);
        }
      }
      roleSet.add("recruiter");
      const sortedRoles = Array.from(roleSet).sort();

      transaction.set(usersRef, {
        uid,
        email,
        name: resolvedName,
        display_name: resolvedName,
        primary_role: "recruiter",
        roles: sortedRoles,
        updated_at: now,
        ...(usersDoc.exists ? {} : { created_at: now }),
      }, { merge: true });
    });

    const syncResult = await syncRecruiterClaimsFromFirestore(uid, {
      source: "registerRecruiterFreelance",
    });

    logger.info("Freelance recruiter registered", {
      uid,
      claimsUpdated: syncResult.updated,
    });

    return {
      success: true,
      claimsUpdated: syncResult.updated,
    };
  });
