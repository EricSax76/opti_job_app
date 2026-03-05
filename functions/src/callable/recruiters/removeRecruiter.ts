/**
 * Callable: removeRecruiter
 *
 * Permite a un admin deshabilitar (status → 'disabled') a un reclutador
 * de su empresa. No elimina el documento (preserva auditoría).
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Recruiter } from "../../types/models";
import { requireSecondFactor } from "../../utils/mfa";
import { syncRecruiterClaimsFromFirestore } from "../../utils/recruiterClaims";

const logger = createLogger({ function: "removeRecruiter" });

interface RemoveRecruiterRequest {
  targetUid: string;
}

export const removeRecruiter = functions
  .region("europe-west1")
  .https.onCall(async (data: RemoveRecruiterRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión."
      );
    }
    requireSecondFactor(context);
    const payload = (data ?? {}) as RemoveRecruiterRequest;

    const callerUid = context.auth.uid;
    const targetUid = typeof payload.targetUid === "string" ? payload.targetUid.trim() : "";

    if (!targetUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUid es obligatorio."
      );
    }

    if (callerUid === targetUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "No puedes eliminarte a ti mismo."
      );
    }

    const db = admin.firestore();

    // Validar caller como admin activo
    const callerDoc = await db.collection("recruiters").doc(callerUid).get();
    if (!callerDoc.exists) {
      throw new functions.https.HttpsError("permission-denied", "No eres reclutador.");
    }
    const caller = callerDoc.data() as Recruiter;
    if (caller.role !== "admin" || caller.status !== "active") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Solo los administradores pueden eliminar reclutadores."
      );
    }

    // Validar target pertenece a la misma empresa
    const targetDoc = await db.collection("recruiters").doc(targetUid).get();
    if (!targetDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Reclutador no encontrado.");
    }
    const target = targetDoc.data() as Recruiter;
    if (target.companyId !== caller.companyId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "El reclutador no pertenece a tu empresa."
      );
    }

    await db.collection("recruiters").doc(targetUid).update({
      status: "disabled",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const syncResult = await syncRecruiterClaimsFromFirestore(targetUid, {
      revokeRefreshTokens: true,
      source: "removeRecruiter",
    });

    logger.info("Recruiter disabled", {
      callerUid,
      targetUid,
      claimsUpdated: syncResult.updated,
    });

    return {
      success: true,
      claimsUpdated: syncResult.updated,
    };
  });
