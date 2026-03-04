/**
 * Callable: updateRecruiterRole
 *
 * Permite a un admin cambiar el rol de otro reclutador de su empresa.
 * Solo puede degradar/elevar roles; no puede cambiar su propio rol.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Recruiter } from "../../types/models";

const logger = createLogger({ function: "updateRecruiterRole" });

interface UpdateRecruiterRoleRequest {
  targetUid: string;
  newRole: "admin" | "recruiter" | "hiring_manager" | "external_evaluator" | "viewer";
}

export const updateRecruiterRole = functions
  .region("europe-west1")
  .https.onCall(async (data: UpdateRecruiterRoleRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión."
      );
    }

    const callerUid = context.auth.uid;

    if (callerUid === data.targetUid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "No puedes cambiar tu propio rol."
      );
    }

    const validRoles = ["admin", "recruiter", "hiring_manager", "external_evaluator", "viewer"];
    if (!validRoles.includes(data.newRole)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Rol inválido."
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
        "Solo los administradores pueden cambiar roles."
      );
    }

    // Validar target pertenece a la misma empresa
    const targetDoc = await db.collection("recruiters").doc(data.targetUid).get();
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

    await db.collection("recruiters").doc(data.targetUid).update({
      role: data.newRole,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("Recruiter role updated", {
      callerUid,
      targetUid: data.targetUid,
      newRole: data.newRole,
    });

    return { success: true };
  });
