/**
 * Firestore Trigger: onRecruiterCreate
 *
 * Se ejecuta cuando se crea un nuevo documento en recruiters/{uid}.
 * Incrementa recruiterCount en companies/{companyId}.
 */

import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";
import { Recruiter } from "../../types/models";

const logger = createLogger({ function: "onRecruiterCreate" });

export const onRecruiterCreate = functions
  .region("europe-west1")
  .firestore.document("recruiters/{uid}")
  .onCreate(async (snapshot, context) => {
    const uid = context.params.uid;
    const recruiter = snapshot.data() as Recruiter;
    const { companyId } = recruiter;

    if (!companyId) {
      logger.warn("onRecruiterCreate: missing companyId", { uid });
      return;
    }

    try {
      const db = admin.firestore();
      await db
        .collection("companies")
        .doc(companyId)
        .update({
          recruiterCount: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      logger.info("recruiterCount incremented", { companyId, uid });
    } catch (error) {
      logger.error("Error incrementing recruiterCount", error, { companyId, uid });
      // No lanzar error — no queremos cancelar la creación del reclutador
    }
  });
