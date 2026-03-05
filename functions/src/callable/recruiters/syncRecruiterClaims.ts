import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { requireSecondFactor } from "../../utils/mfa";
import { Recruiter } from "../../types/models";
import { syncRecruiterClaimsFromFirestore } from "../../utils/recruiterClaims";

const logger = createLogger({ function: "syncRecruiterClaims" });

interface SyncRecruiterClaimsRequest {
  targetUid?: string;
  revokeTokens?: boolean;
}

function normalizeTargetUid(
  data: SyncRecruiterClaimsRequest,
  fallbackUid: string,
): string {
  if (typeof data.targetUid !== "string") {
    return fallbackUid;
  }

  const targetUid = data.targetUid.trim();
  return targetUid.length > 0 ? targetUid : fallbackUid;
}

export const syncRecruiterClaims = functions
  .region("europe-west1")
  .https.onCall(async (data: SyncRecruiterClaimsRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Debes iniciar sesión.",
      );
    }

    requireSecondFactor(context);

    const callerUid = context.auth.uid;
    const payload = (data ?? {}) as SyncRecruiterClaimsRequest;
    const targetUid = normalizeTargetUid(payload, callerUid);
    const revokeTokens = payload.revokeTokens === true;
    const db = admin.firestore();

    if (targetUid !== callerUid) {
      const callerDoc = await db.collection("recruiters").doc(callerUid).get();
      if (!callerDoc.exists) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "No eres reclutador.",
        );
      }

      const callerRecruiter = callerDoc.data() as Recruiter;
      if (callerRecruiter.status !== "active" || callerRecruiter.role !== "admin") {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Solo un admin activo puede sincronizar claims de otros usuarios.",
        );
      }

      const targetDoc = await db.collection("recruiters").doc(targetUid).get();
      if (!targetDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Reclutador objetivo no encontrado.",
        );
      }

      const targetRecruiter = targetDoc.data() as Recruiter;
      if (targetRecruiter.companyId !== callerRecruiter.companyId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Solo puedes sincronizar reclutadores de tu empresa.",
        );
      }
    }

    const result = await syncRecruiterClaimsFromFirestore(targetUid, {
      revokeRefreshTokens: revokeTokens,
      source: targetUid === callerUid ? "callable-self" : "callable-admin",
    });

    logger.info("syncRecruiterClaims executed", {
      callerUid,
      targetUid,
      updated: result.updated,
      recruiterFound: result.recruiterFound,
      revokedTokens: result.revokedTokens,
    });

    return {
      success: true,
      targetUid: result.uid,
      recruiterFound: result.recruiterFound,
      updated: result.updated,
      revokedTokens: result.revokedTokens,
      managedClaims: result.managedClaims,
    };
  });
