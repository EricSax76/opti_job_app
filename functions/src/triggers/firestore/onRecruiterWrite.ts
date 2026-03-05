import * as functions from "firebase-functions/v1";
import { Recruiter } from "../../types/models";
import { createLogger } from "../../utils/logger";
import { syncRecruiterClaims } from "../../utils/recruiterClaims";

const logger = createLogger({ function: "onRecruiterWrite" });

function claimsRelevantChange(
  before: Recruiter | null,
  after: Recruiter | null,
): boolean {
  if (before === null && after === null) {
    return false;
  }

  if (before === null || after === null) {
    return true;
  }

  return (
    before.role !== after.role ||
    before.status !== after.status ||
    before.companyId !== after.companyId
  );
}

export const onRecruiterWrite = functions
  .region("europe-west1")
  .firestore.document("recruiters/{uid}")
  .onWrite(async (change, context) => {
    const uid = context.params.uid as string;
    const before = change.before.exists ?
      (change.before.data() as Recruiter) :
      null;
    const after = change.after.exists ?
      (change.after.data() as Recruiter) :
      null;

    const revokeRefreshTokens = claimsRelevantChange(before, after);

    try {
      const result = await syncRecruiterClaims(uid, after, {
        revokeRefreshTokens,
        source: "trigger-onRecruiterWrite",
      });

      logger.info("Recruiter claims synced by trigger", {
        uid,
        updated: result.updated,
        recruiterFound: result.recruiterFound,
        revokedTokens: result.revokedTokens,
      });
    } catch (error) {
      logger.error("Failed to sync recruiter claims from trigger", error, { uid });
    }
  });
