/**
 * Callable: acceptInvitation
 *
 * Permite a un usuario autenticado canjear un código de invitación
 * para unirse a una empresa como reclutador.
 *
 * Operación atómica (transacción Firestore):
 * 1. Lee y valida la invitación.
 * 2. Crea recruiters/{uid}.
 * 3. Marca invitations/{code}.status = 'accepted'.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Recruiter, Invitation } from "../../types/models";
import { requireSecondFactor } from "../../utils/mfa";
import { syncRecruiterClaimsFromFirestore } from "../../utils/recruiterClaims";

const logger = createLogger({ function: "acceptInvitation" });

interface AcceptInvitationRequest {
  code: string;
  name: string;
}

export const acceptInvitation = functions
  .region("europe-west1")
  .https.onCall(async (data: AcceptInvitationRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión para aceptar una invitación."
      );
    }
    requireSecondFactor(context);
    const payload = (data ?? {}) as AcceptInvitationRequest;

    if (!payload.code || typeof payload.code !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Código de invitación requerido."
      );
    }

    const uid = context.auth.uid;
    const email = context.auth.token.email || "";
    const code = payload.code.toUpperCase().trim();
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    await db.runTransaction(async (transaction) => {
      const invitationRef = db.collection("invitations").doc(code);
      const invitationDoc = await transaction.get(invitationRef);

      if (!invitationDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Invitación no encontrada."
        );
      }

      const invitation = invitationDoc.data() as Invitation;
      const invitationCompanyId = String(invitation.companyId ?? "").trim();
      if (!invitationCompanyId) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "La invitación no tiene una empresa válida."
        );
      }

      if (invitation.status !== "pending") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Esta invitación ya fue usada o está expirada."
        );
      }

      const expiresAt = invitation.expiresAt as admin.firestore.Timestamp;
      if (now.seconds > expiresAt.seconds) {
        throw new functions.https.HttpsError(
          "deadline-exceeded",
          "La invitación ha caducado (72h)."
        );
      }

      // Verificar/actualizar recruiter existente.
      const recruiterRef = db.collection("recruiters").doc(uid);
      const existingRecruiter = await transaction.get(recruiterRef);
      if (existingRecruiter.exists) {
        const recruiter = existingRecruiter.data() as Recruiter;
        const existingCompanyId = String(recruiter.companyId ?? "").trim();

        if (existingCompanyId && existingCompanyId !== invitationCompanyId) {
          throw new functions.https.HttpsError(
            "already-exists",
            "Ya eres miembro de otra empresa."
          );
        }

        if (existingCompanyId && recruiter.status === "active") {
          throw new functions.https.HttpsError(
            "already-exists",
            "Ya eres miembro activo de esta empresa."
          );
        }

        transaction.set(
          recruiterRef,
          {
            companyId: invitationCompanyId,
            email,
            name: payload.name || recruiter.name || email.split("@")[0],
            role: invitation.role,
            status: "active",
            invitedBy: invitation.createdBy,
            invitedAt: invitation.createdAt,
            acceptedAt: now,
            updatedAt: now,
          },
          { merge: true }
        );
      } else {
        const recruiter: Recruiter = {
          uid,
          companyId: invitationCompanyId,
          email,
          name: payload.name || email.split("@")[0],
          role: invitation.role,
          status: "active",
          invitedBy: invitation.createdBy,
          invitedAt: invitation.createdAt,
          acceptedAt: now,
          createdAt: now,
          updatedAt: now,
        };

        transaction.set(recruiterRef, recruiter);
      }
      transaction.update(invitationRef, {
        status: "accepted",
        usedBy: uid,
      });
    });

    const syncResult = await syncRecruiterClaimsFromFirestore(uid, {
      source: "acceptInvitation",
    });

    logger.info("Invitation accepted", { uid, code });

    return {
      success: true,
      claimsUpdated: syncResult.updated,
    };
  });
