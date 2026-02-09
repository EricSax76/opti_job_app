#!/usr/bin/env node

/**
 * One-shot migration for applications legacy schema -> canonical schema.
 *
 * Canonical fields:
 * - jobOfferId (string)
 * - companyUid (string, optional)
 * - candidateId (string)
 * - createdAt (Timestamp, optional)
 * - updatedAt (Timestamp, optional)
 *
 * Legacy fields removed by default:
 * - job_offer_id
 * - company_uid
 * - candidate_uid
 * - candidate_id
 * - job_offer_title
 * - candidate_name
 * - candidate_email
 * - candidate_profile_id
 * - curriculum_id
 * - cover_letter
 * - created_at
 * - updated_at
 * - submitted_at
 * - submittedAt
 *
 * Usage:
 *   node scripts/migrate-applications-schema.js --dry-run
 *   node scripts/migrate-applications-schema.js --apply
 *   node scripts/migrate-applications-schema.js --apply --max-documents=5000
 */

const admin = require("firebase-admin");

const DEFAULT_PAGE_SIZE = 400;
const DEFAULT_COMMIT_SIZE = 400;
const DEFAULT_SAMPLE_SIZE = 20;
const MAX_PAGE_SIZE = 500;
const MAX_COMMIT_SIZE = 450;

const LEGACY_FIELDS = [
  "job_offer_id",
  "company_uid",
  "candidate_uid",
  "candidate_id",
  "job_offer_title",
  "candidate_name",
  "candidate_email",
  "candidate_profile_id",
  "curriculum_id",
  "cover_letter",
  "created_at",
  "updated_at",
  "submitted_at",
  "submittedAt",
];

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printHelp();
    return;
  }

  const appConfig = {};
  if (options.projectId) {
    appConfig.projectId = options.projectId;
  }
  admin.initializeApp(appConfig);

  const db = admin.firestore();

  const summary = {
    mode: options.apply ? "apply" : "dry-run",
    scanned: 0,
    toUpdate: 0,
    unchanged: 0,
    skipped: 0,
    committedWrites: 0,
    commits: 0,
    nextCursor: null,
    samples: [],
    skipReasons: {},
  };

  let pending = [];
  let lastDocId = options.startAfterId;
  let reachedMaxDocuments = false;

  while (true) {
    let query = db
      .collection("applications")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(options.pageSize);

    if (lastDocId) {
      query = query.startAfter(lastDocId);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    for (const doc of snapshot.docs) {
      summary.scanned += 1;
      lastDocId = doc.id;

      const plan = buildUpdatePlan(doc.data());
      if (plan.skipReason) {
        summary.skipped += 1;
        summary.skipReasons[plan.skipReason] =
          (summary.skipReasons[plan.skipReason] || 0) + 1;
      } else if (!plan.hasChanges) {
        summary.unchanged += 1;
      } else {
        summary.toUpdate += 1;
        if (summary.samples.length < options.sampleSize) {
          summary.samples.push({
            docId: doc.id,
            changedFields: Object.keys(plan.updateData),
          });
        }

        if (options.apply) {
          pending.push({ ref: doc.ref, updateData: plan.updateData });
          if (pending.length >= options.commitSize) {
            await commitPending(db, pending);
            summary.committedWrites += pending.length;
            summary.commits += 1;
            pending = [];
          }
        }
      }

      if (
        options.maxDocuments != null &&
        summary.scanned >= options.maxDocuments
      ) {
        reachedMaxDocuments = true;
        break;
      }
    }

    if (reachedMaxDocuments || snapshot.size < options.pageSize) {
      break;
    }
  }

  if (options.apply && pending.length > 0) {
    await commitPending(db, pending);
    summary.committedWrites += pending.length;
    summary.commits += 1;
  }

  if (reachedMaxDocuments && lastDocId) {
    summary.nextCursor = lastDocId;
  }

  console.log(JSON.stringify(summary, null, 2));
}

function buildUpdatePlan(data) {
  const updateData = {};
  let hasChanges = false;

  const jobOfferId = pickNonEmptyString(data.jobOfferId, data.job_offer_id);
  if (!jobOfferId) {
    return { hasChanges: false, updateData: {}, skipReason: "missing_jobOfferId" };
  }

  const candidateId = pickNonEmptyString(
    data.candidateId,
    data.candidate_uid,
    data.candidate_id
  );
  if (!candidateId) {
    return { hasChanges: false, updateData: {}, skipReason: "missing_candidateId" };
  }

  hasChanges = setString(updateData, data, "jobOfferId", jobOfferId) || hasChanges;
  hasChanges = setString(updateData, data, "candidateId", candidateId) || hasChanges;

  const companyUid = pickNonEmptyString(data.companyUid, data.company_uid);
  if (companyUid) {
    hasChanges = setString(updateData, data, "companyUid", companyUid) || hasChanges;
  }

  const jobOfferTitle = pickNonEmptyString(
    data.jobOfferTitle,
    data.job_offer_title
  );
  if (jobOfferTitle) {
    hasChanges =
      setString(updateData, data, "jobOfferTitle", jobOfferTitle) || hasChanges;
  }

  const candidateName = pickNonEmptyString(
    data.candidateName,
    data.candidate_name
  );
  if (candidateName) {
    hasChanges =
      setString(updateData, data, "candidateName", candidateName) || hasChanges;
  }

  const candidateEmail = pickNonEmptyString(
    data.candidateEmail,
    data.candidate_email
  );
  if (candidateEmail) {
    hasChanges =
      setString(updateData, data, "candidateEmail", candidateEmail) || hasChanges;
  }

  const curriculumId = pickNonEmptyString(data.curriculumId, data.curriculum_id);
  if (curriculumId) {
    hasChanges =
      setString(updateData, data, "curriculumId", curriculumId) || hasChanges;
  }

  const status = pickNonEmptyString(data.status);
  if (status) {
    hasChanges = setString(updateData, data, "status", status) || hasChanges;
  }

  const coverLetter = pickDefinedString(data.coverLetter, data.cover_letter);
  if (coverLetter !== undefined) {
    hasChanges =
      setRawString(updateData, data, "coverLetter", coverLetter) || hasChanges;
  }

  const candidateProfileId = pickInteger(
    data.candidateProfileId,
    data.candidate_profile_id
  );
  if (candidateProfileId !== undefined) {
    hasChanges =
      setNumber(updateData, data, "candidateProfileId", candidateProfileId) ||
      hasChanges;
  }

  const createdAt = pickTimestamp(
    data.createdAt,
    data.created_at,
    data.submittedAt,
    data.submitted_at
  );
  if (createdAt) {
    hasChanges = setTimestamp(updateData, data, "createdAt", createdAt) || hasChanges;
  }

  const updatedAt = pickTimestamp(
    data.updatedAt,
    data.updated_at,
    data.submittedAt,
    data.submitted_at,
    data.createdAt,
    data.created_at
  );
  if (updatedAt) {
    hasChanges = setTimestamp(updateData, data, "updatedAt", updatedAt) || hasChanges;
  }

  for (const field of LEGACY_FIELDS) {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      updateData[field] = admin.firestore.FieldValue.delete();
      hasChanges = true;
    }
  }

  return { hasChanges, updateData };
}

function pickNonEmptyString(...values) {
  for (const value of values) {
    if (value === null || value === undefined) continue;
    const normalized = String(value).trim();
    if (normalized) return normalized;
  }
  return undefined;
}

function pickDefinedString(...values) {
  for (const value of values) {
    if (value === null || value === undefined) continue;
    return String(value);
  }
  return undefined;
}

function pickInteger(...values) {
  for (const value of values) {
    if (value === null || value === undefined) continue;
    if (typeof value === "number" && Number.isFinite(value)) {
      return Math.trunc(value);
    }
    const parsed = Number.parseInt(String(value), 10);
    if (!Number.isNaN(parsed)) return parsed;
  }
  return undefined;
}

function pickTimestamp(...values) {
  for (const value of values) {
    const normalized = normalizeTimestamp(value);
    if (normalized) return normalized;
  }
  return undefined;
}

function normalizeTimestamp(value) {
  if (value === null || value === undefined) return undefined;
  if (value instanceof admin.firestore.Timestamp) return value;

  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return undefined;
    return admin.firestore.Timestamp.fromDate(value);
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    return admin.firestore.Timestamp.fromMillis(value);
  }

  if (typeof value === "string") {
    const date = new Date(value);
    if (!Number.isNaN(date.getTime())) {
      return admin.firestore.Timestamp.fromDate(date);
    }
  }

  return undefined;
}

function setString(updateData, currentData, field, nextValue) {
  const currentValue = currentData[field];
  const normalizedCurrent =
    currentValue === null || currentValue === undefined
      ? undefined
      : String(currentValue).trim();
  if (normalizedCurrent === nextValue) return false;
  updateData[field] = nextValue;
  return true;
}

function setRawString(updateData, currentData, field, nextValue) {
  const currentValue = currentData[field];
  const normalizedCurrent =
    currentValue === null || currentValue === undefined
      ? undefined
      : String(currentValue);
  if (normalizedCurrent === nextValue) return false;
  updateData[field] = nextValue;
  return true;
}

function setNumber(updateData, currentData, field, nextValue) {
  const currentValue = currentData[field];
  const normalizedCurrent =
    currentValue === null || currentValue === undefined
      ? undefined
      : Number.parseInt(String(currentValue), 10);
  if (normalizedCurrent === nextValue) return false;
  updateData[field] = nextValue;
  return true;
}

function setTimestamp(updateData, currentData, field, nextValue) {
  const currentValue = normalizeTimestamp(currentData[field]);
  if (currentValue && currentValue.toMillis() === nextValue.toMillis()) {
    return false;
  }
  updateData[field] = nextValue;
  return true;
}

async function commitPending(db, pending) {
  const batch = db.batch();
  for (const entry of pending) {
    batch.update(entry.ref, entry.updateData);
  }
  await batch.commit();
}

function parseArgs(args) {
  const envProjectId =
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID ||
    null;
  const emulatorProjectId = process.env.FIRESTORE_EMULATOR_HOST
    ? "demo-project"
    : null;

  const options = {
    apply: false,
    help: false,
    pageSize: DEFAULT_PAGE_SIZE,
    commitSize: DEFAULT_COMMIT_SIZE,
    sampleSize: DEFAULT_SAMPLE_SIZE,
    maxDocuments: null,
    startAfterId: null,
    projectId: envProjectId || emulatorProjectId,
  };

  for (const arg of args) {
    if (arg === "--help" || arg === "-h") {
      options.help = true;
      continue;
    }
    if (arg === "--apply") {
      options.apply = true;
      continue;
    }
    if (arg === "--dry-run") {
      options.apply = false;
      continue;
    }
    if (arg.startsWith("--page-size=")) {
      options.pageSize = clampInt(
        parseIntAfterEquals(arg),
        1,
        MAX_PAGE_SIZE,
        DEFAULT_PAGE_SIZE
      );
      continue;
    }
    if (arg.startsWith("--commit-size=")) {
      options.commitSize = clampInt(
        parseIntAfterEquals(arg),
        1,
        MAX_COMMIT_SIZE,
        DEFAULT_COMMIT_SIZE
      );
      continue;
    }
    if (arg.startsWith("--sample-size=")) {
      options.sampleSize = clampInt(
        parseIntAfterEquals(arg),
        0,
        200,
        DEFAULT_SAMPLE_SIZE
      );
      continue;
    }
    if (arg.startsWith("--max-documents=")) {
      const parsed = parseIntAfterEquals(arg);
      options.maxDocuments =
        Number.isFinite(parsed) && parsed > 0 ? Math.trunc(parsed) : null;
      continue;
    }
    if (arg.startsWith("--start-after-id=")) {
      const value = arg.split("=")[1];
      options.startAfterId = value ? String(value) : null;
      continue;
    }
    if (arg.startsWith("--project-id=")) {
      const value = arg.split("=")[1];
      options.projectId = value ? String(value) : null;
      continue;
    }
  }

  return options;
}

function parseIntAfterEquals(arg) {
  const value = arg.split("=")[1];
  return Number.parseInt(value, 10);
}

function clampInt(value, min, max, fallback) {
  if (!Number.isFinite(value)) return fallback;
  return Math.max(min, Math.min(max, Math.trunc(value)));
}

function printHelp() {
  console.log(`
Usage:
  node scripts/migrate-applications-schema.js [options]

Options:
  --dry-run                Scan and report only (default)
  --apply                  Execute updates
  --page-size=<n>          Read page size (default: ${DEFAULT_PAGE_SIZE}, max: ${MAX_PAGE_SIZE})
  --commit-size=<n>        Batch commit size (default: ${DEFAULT_COMMIT_SIZE}, max: ${MAX_COMMIT_SIZE})
  --max-documents=<n>      Stop after scanning N docs (for staged runs)
  --start-after-id=<id>    Resume after this document id
  --project-id=<id>        Firebase project id (uses env vars by default)
  --sample-size=<n>        Number of sample docs in summary (default: ${DEFAULT_SAMPLE_SIZE})
  --help, -h               Show this message
`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
