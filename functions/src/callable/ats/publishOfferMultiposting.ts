import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const SUPPORTED_CHANNELS = ["linkedin", "indeed", "university_portal"] as const;
type SupportedChannel = typeof SUPPORTED_CHANNELS[number];

function normalizeChannel(value: unknown): SupportedChannel | null {
  const raw = String(value ?? "").trim().toLowerCase();
  if (raw === "linkedin") return "linkedin";
  if (raw === "indeed") return "indeed";
  if (raw === "university_portal" || raw === "university" || raw === "universities") {
    return "university_portal";
  }
  return null;
}

function normalizeChannels(raw: unknown): SupportedChannel[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    return [...SUPPORTED_CHANNELS];
  }
  const normalized = raw
    .map(normalizeChannel)
    .filter((value): value is SupportedChannel => value !== null);
  return normalized.length > 0 ? Array.from(new Set(normalized)) : [...SUPPORTED_CHANNELS];
}

function pickNonEmptyString(...values: unknown[]): string {
  for (const value of values) {
    const normalized = String(value ?? "").trim();
    if (normalized.length > 0) return normalized;
  }
  return "";
}

async function assertCanManageOffer(
  db: FirebaseFirestore.Firestore,
  actorUid: string,
  companyId: string,
): Promise<void> {
  if (actorUid === companyId) return;
  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Only company users or recruiters with publishing permissions can multipost.",
    );
  }
  const recruiter = recruiterDoc.data() as Record<string, unknown>;
  const recruiterCompanyId = String(recruiter.companyId ?? "").trim();
  const recruiterStatus = String(recruiter.status ?? "").trim();
  const recruiterRole = String(recruiter.role ?? "").trim();
  const canManageOffers = recruiterRole === "admin" || recruiterRole === "recruiter";
  if (recruiterCompanyId !== companyId || recruiterStatus !== "active" || !canManageOffers) {
    throw new HttpsError(
      "permission-denied",
      "Your role cannot publish this offer to external channels.",
    );
  }
}

function buildTrackingUrl(offerId: string, channel: SupportedChannel): string {
  const base =
    process.env.PUBLIC_JOB_BASE_URL?.trim() ||
    "https://optimizzate-eb14a.web.app";
  return `${base}/job-offer/${offerId}?source=${channel}`;
}

export const publishOfferMultiposting = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const offerId = pickNonEmptyString(request.data?.jobOfferId, request.data?.offerId);
  if (!offerId) {
    throw new HttpsError("invalid-argument", "jobOfferId es obligatorio.");
  }

  const channels = normalizeChannels(request.data?.channels);
  const db = getFirestore();
  const actorUid = request.auth.uid;
  const offerRef = db.collection("jobOffers").doc(offerId);
  const offerDoc = await offerRef.get();
  if (!offerDoc.exists) {
    throw new HttpsError("not-found", "Oferta no encontrada.");
  }

  const offer = offerDoc.data() as Record<string, unknown>;
  const companyId = pickNonEmptyString(
    offer.company_uid,
    offer.companyUid,
    offer.owner_uid,
  );
  if (!companyId) {
    throw new HttpsError(
      "failed-precondition",
      "La oferta no contiene empresa propietaria.",
    );
  }

  await assertCanManageOffer(db, actorUid, companyId);

  const now = FieldValue.serverTimestamp();
  const publications = channels.map((channel) => {
    const trackingUrl = buildTrackingUrl(offerId, channel);
    return {
      channel,
      trackingUrl,
      publicationId: `${offerId}_${channel}`,
      externalPostId: `mvp_${channel}_${offerId}`,
    };
  });

  const batch = db.batch();
  for (const publication of publications) {
    const ref = db.collection("multipostingPublications").doc(publication.publicationId);
    batch.set(
      ref,
      {
        id: publication.publicationId,
        offerId,
        companyId,
        channel: publication.channel,
        status: "published",
        trackingUrl: publication.trackingUrl,
        externalPostId: publication.externalPostId,
        publishedBy: actorUid,
        publishedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
  }

  const offerUpdates: Record<string, unknown> = {
    multiposting_enabled_channels: channels,
    multiposting_updated_at: now,
    updated_at: now,
  };
  for (const publication of publications) {
    offerUpdates[`multiposting.channels.${publication.channel}`] = {
      status: "published",
      trackingUrl: publication.trackingUrl,
      externalPostId: publication.externalPostId,
      publishedBy: actorUid,
      publishedAt: now,
    };
  }
  batch.set(offerRef, offerUpdates, { merge: true });

  await batch.commit();

  return {
    ok: true,
    offerId,
    companyId,
    channels: publications.map((row) => ({
      channel: row.channel,
      trackingUrl: row.trackingUrl,
      status: "published",
    })),
  };
});
