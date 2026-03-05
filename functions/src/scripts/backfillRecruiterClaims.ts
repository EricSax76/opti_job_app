import * as admin from "firebase-admin";
import { Recruiter } from "../types/models";
import { syncRecruiterClaims } from "../utils/recruiterClaims";

interface CliOptions {
  dryRun: boolean;
  companyId: string | null;
  limit: number | null;
}

function parseArgs(argv: string[]): CliOptions {
  let dryRun = false;
  let companyId: string | null = null;
  let limit: number | null = null;

  for (const arg of argv) {
    if (arg === "--dry-run") {
      dryRun = true;
      continue;
    }

    if (arg.startsWith("--companyId=")) {
      companyId = arg.replace("--companyId=", "").trim() || null;
      continue;
    }

    if (arg.startsWith("--limit=")) {
      const rawLimit = Number(arg.replace("--limit=", "").trim());
      if (Number.isFinite(rawLimit) && rawLimit > 0) {
        limit = Math.floor(rawLimit);
      }
    }
  }

  return { dryRun, companyId, limit };
}

async function run(): Promise<void> {
  if (admin.apps.length === 0) {
    admin.initializeApp();
  }

  const options = parseArgs(process.argv.slice(2));
  const db = admin.firestore();

  let query: FirebaseFirestore.Query = db.collection("recruiters");
  if (options.companyId) {
    query = query.where("companyId", "==", options.companyId);
  }

  const snapshot = await query.get();
  const docs = options.limit ? snapshot.docs.slice(0, options.limit) : snapshot.docs;

  console.log(
    `[backfillRecruiterClaims] recruiters encontrados=${snapshot.size}, procesando=${docs.length}, dryRun=${options.dryRun}`,
  );

  let updated = 0;
  let unchanged = 0;
  let missingAuthUser = 0;
  let errors = 0;

  for (const doc of docs) {
    const uid = doc.id;
    const recruiter = doc.data() as Recruiter;

    try {
      const result = await syncRecruiterClaims(uid, recruiter, {
        dryRun: options.dryRun,
        source: "backfill-recruiter-claims",
      });

      if (!result.authUserFound) {
        missingAuthUser += 1;
        console.warn(
          `[backfillRecruiterClaims] auth user no encontrado uid=${uid}`,
        );
        continue;
      }

      if (!result.recruiterFound) {
        unchanged += 1;
      } else if (result.updated) {
        updated += 1;
      } else {
        unchanged += 1;
      }
    } catch (error) {
      const err = error as { message?: string };
      errors += 1;
      console.error(
        `[backfillRecruiterClaims] error uid=${uid}: ${err.message || String(error)}`,
      );
    }
  }

  console.log("[backfillRecruiterClaims] resumen", {
    updated,
    unchanged,
    missingAuthUser,
    errors,
    dryRun: options.dryRun,
    companyId: options.companyId,
    processed: docs.length,
  });

  if (errors > 0) {
    process.exitCode = 1;
  }
}

run().catch((error) => {
  console.error("[backfillRecruiterClaims] fallo fatal", error);
  process.exit(1);
});
