import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import { createLogger } from "../../utils/logger";

const logger = createLogger({ module: "syncDenormalizedFields" });

const BATCH_LIMIT = 400;

type JsonRecord = Record<string, unknown>;

function asRecord(value: unknown): JsonRecord {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as JsonRecord;
}

function normalizedString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const normalized = String(value).trim();
  return normalized.length > 0 ? normalized : null;
}

function sameValue(left: string | null, right: string | null): boolean {
  return left === right;
}

function extractVideoStoragePath(data: JsonRecord): string | null {
  const video = asRecord(data.video_curriculum);
  return normalizedString(video.storage_path);
}

function isDeleteSentinel(value: unknown): boolean {
  if (value == null || typeof value !== "object") {
    return false;
  }
  return value.constructor?.name === "DeleteTransform";
}

function hasRealUpdates(updates: JsonRecord): boolean {
  return Object.keys(updates).length > 0;
}

async function dedupeDocs(
  snapshots: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>[],
): Promise<FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[]> {
  const byPath = new Map<
    string,
    FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
  >();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      byPath.set(doc.ref.path, doc);
    }
  }
  return [...byPath.values()];
}

async function batchUpdateDocs(
  docs: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[],
  updates: JsonRecord,
): Promise<number> {
  if (docs.length === 0 || !hasRealUpdates(updates)) {
    return 0;
  }

  const db = admin.firestore();
  let batch = db.batch();
  let pending = 0;
  let updated = 0;

  for (const doc of docs) {
    batch.update(doc.ref, updates);
    pending += 1;
    updated += 1;

    if (pending >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }

  if (pending > 0) {
    await batch.commit();
  }

  return updated;
}

export const syncCandidateProfileToApplications = functions
  .region("europe-west1")
  .firestore
  .document("candidates/{candidateUid}")
  .onUpdate(async (change, context) => {
    const candidateUid = String(context.params.candidateUid || "").trim();
    if (!candidateUid) return;

    const before = asRecord(change.before.data());
    const after = asRecord(change.after.data());

    const beforeName = normalizedString(before.name);
    const afterName = normalizedString(after.name);
    const beforeEmail = normalizedString(before.email);
    const afterEmail = normalizedString(after.email);
    const beforeAvatar = normalizedString(before.avatar_url);
    const afterAvatar = normalizedString(after.avatar_url);
    const beforeVideoPath = extractVideoStoragePath(before);
    const afterVideoPath = extractVideoStoragePath(after);

    const updates: JsonRecord = {};
    if (!sameValue(beforeName, afterName) && afterName !== null) {
      updates.candidate_name = afterName;
      updates.candidateName = afterName;
    }

    if (!sameValue(beforeEmail, afterEmail) && afterEmail !== null) {
      updates.candidate_email = afterEmail;
      updates.candidateEmail = afterEmail;
    }

    if (!sameValue(beforeAvatar, afterAvatar)) {
      if (afterAvatar === null) {
        updates.candidate_avatar_url = admin.firestore.FieldValue.delete();
        updates.candidateAvatarUrl = admin.firestore.FieldValue.delete();
      } else {
        updates.candidate_avatar_url = afterAvatar;
        updates.candidateAvatarUrl = afterAvatar;
      }
    }

    if (!sameValue(beforeVideoPath, afterVideoPath)) {
      const hasVideoCurriculum = afterVideoPath !== null;
      updates.has_video_curriculum = hasVideoCurriculum;
      updates.hasVideoCurriculum = hasVideoCurriculum;
    }

    if (!hasRealUpdates(updates)) {
      return;
    }

    const db = admin.firestore();

    // Use query combination if exact match is required for candidate UID fields
    // Because Firestore allows max 10 array items for `in`, and we query across 3 fields, 
    // it's better to keep `Promise.all` but check for overlaps in the same field if there were any.
    // In this specific case, to reduce the 3 queries into 1, we can use an `or` query logic
    // but Firestore Node.js module supports `Filter.or(...)` 
    const snapshots = await Promise.all([
      db.collection("applications").where(admin.firestore.Filter.or(
        admin.firestore.Filter.where("candidate_uid", "==", candidateUid),
        admin.firestore.Filter.where("candidateId", "==", candidateUid),
        admin.firestore.Filter.where("candidate_id", "==", candidateUid)
      )).get()
    ]);
    const docs = await dedupeDocs(snapshots);
    const updated = await batchUpdateDocs(docs, updates);

    logger.info("Candidate profile synced to applications", {
      candidateUid,
      matchedDocs: docs.length,
      updated,
      updatedFields: Object.keys(updates).filter((k) => !isDeleteSentinel(updates[k])),
    });
  });

export const syncCompanyProfileToOffers = functions
  .region("europe-west1")
  .firestore
  .document("companies/{companyUid}")
  .onUpdate(async (change, context) => {
    const companyUid = String(context.params.companyUid || "").trim();
    if (!companyUid) return;

    const before = asRecord(change.before.data());
    const after = asRecord(change.after.data());

    const beforeName = normalizedString(before.name);
    const afterName = normalizedString(after.name);
    const beforeAvatar = normalizedString(before.avatar_url);
    const afterAvatar = normalizedString(after.avatar_url);

    const updates: JsonRecord = {};
    if (!sameValue(beforeName, afterName) && afterName !== null) {
      updates.company_name = afterName;
      updates.companyName = afterName;
    }

    if (!sameValue(beforeAvatar, afterAvatar)) {
      if (afterAvatar === null) {
        updates.company_avatar_url = admin.firestore.FieldValue.delete();
        updates.companyAvatarUrl = admin.firestore.FieldValue.delete();
      } else {
        updates.company_avatar_url = afterAvatar;
        updates.companyAvatarUrl = afterAvatar;
      }
    }

    if (!hasRealUpdates(updates)) {
      return;
    }

    const db = admin.firestore();
    const snapshots = await Promise.all([
      db.collection("jobOffers").where(admin.firestore.Filter.or(
        admin.firestore.Filter.where("company_uid", "==", companyUid),
        admin.firestore.Filter.where("companyUid", "==", companyUid),
        admin.firestore.Filter.where("owner_uid", "==", companyUid)
      )).get()
    ]);
    const docs = await dedupeDocs(snapshots);
    const updated = await batchUpdateDocs(docs, updates);

    logger.info("Company profile synced to offers", {
      companyUid,
      matchedDocs: docs.length,
      updated,
      updatedFields: Object.keys(updates).filter((k) => !isDeleteSentinel(updates[k])),
    });
  });

export const syncJobOfferTitleToApplications = functions
  .region("europe-west1")
  .firestore
  .document("jobOffers/{offerId}")
  .onUpdate(async (change, context) => {
    const offerId = String(context.params.offerId || "").trim();
    if (!offerId) return;

    const before = asRecord(change.before.data());
    const after = asRecord(change.after.data());

    const beforeTitle = normalizedString(before.title);
    const afterTitle = normalizedString(after.title);
    if (sameValue(beforeTitle, afterTitle)) {
      return;
    }

    const offerIdentifiers = new Set<string>([
      offerId,
      normalizedString(before.id) || "",
      normalizedString(after.id) || "",
    ]);

    const updates: JsonRecord = {};
    if (afterTitle === null) {
      updates.job_offer_title = admin.firestore.FieldValue.delete();
      updates.jobOfferTitle = admin.firestore.FieldValue.delete();
    } else {
      updates.job_offer_title = afterTitle;
      updates.jobOfferTitle = afterTitle;
    }

    const db = admin.firestore();
    const validIdentifiers = [...offerIdentifiers].filter(Boolean);
    const queries: Array<
      Promise<FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>>
    > = [];
    
    // Chunk validIdentifiers into chunks of 10 for 'in' operator limits
    for (let i = 0; i < validIdentifiers.length; i += 10) {
      const chunk = validIdentifiers.slice(i, i + 10);
      queries.push(
        db.collection("applications").where(admin.firestore.Filter.or(
          admin.firestore.Filter.where("job_offer_id", "in", chunk),
          admin.firestore.Filter.where("jobOfferId", "in", chunk)
        )).get()
      );
    }

    if (queries.length === 0) return;
    const snapshots = await Promise.all(queries);
    const docs = await dedupeDocs(snapshots);
    const updated = await batchUpdateDocs(docs, updates);

    logger.info("Job offer title synced to applications", {
      offerId,
      identifiers: [...offerIdentifiers].filter(Boolean),
      matchedDocs: docs.length,
      updated,
    });
  });
