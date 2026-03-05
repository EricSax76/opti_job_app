import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { validateOfferSalaryForPublication } from "./utils/salaryValidation";
import { assertCanManageOffer } from "./utils/atsAccess";
import {
  buildTrackingUrl,
  getCompanyChannelSettings,
  normalizeRequestedChannels,
  resolveChannelCostEur,
  resolveChannelsToPublish,
  CHANNEL_CATALOG,
} from "./utils/multipostingChannels";

function pickNonEmptyString(...values: unknown[]): string {
  for (const value of values) {
    const normalized = String(value ?? "").trim();
    if (normalized.length > 0) return normalized;
  }
  return "";
}

export const publishOfferMultiposting = onCall({ region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const offerId = pickNonEmptyString(request.data?.jobOfferId, request.data?.offerId);
  if (!offerId) {
    throw new HttpsError("invalid-argument", "jobOfferId es obligatorio.");
  }

  const db = getFirestore();
  const actorUid = request.auth.uid;
  const offerRef = db.collection("jobOffers").doc(offerId);
  const offerDoc = await offerRef.get();
  if (!offerDoc.exists) {
    throw new HttpsError("not-found", "Oferta no encontrada.");
  }

  const offer = offerDoc.data() as Record<string, unknown>;
  const companyId = pickNonEmptyString(offer.company_uid, offer.companyUid, offer.owner_uid);
  if (!companyId) {
    throw new HttpsError("failed-precondition", "La oferta no contiene empresa propietaria.");
  }

  await assertCanManageOffer(actorUid, companyId);

  const salaryValidation = validateOfferSalaryForPublication(offer);
  if (!salaryValidation.valid) {
    await offerRef.set(
      {
        status: "blocked_pending_salary_validation",
        publication_block_reason: salaryValidation.reasonCode ?? "invalid_salary_range",
        publication_block_message:
          salaryValidation.reasonMessage ??
          "La oferta no cumple validaciones salariales obligatorias.",
        publication_blocked_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    throw new HttpsError(
      "failed-precondition",
      salaryValidation.reasonMessage ?? "No se puede publicar sin rango salarial válido.",
    );
  }

  const companySettings = await getCompanyChannelSettings(companyId);
  const requestedChannels = normalizeRequestedChannels(request.data?.channels);
  const channels = resolveChannelsToPublish(requestedChannels, companySettings);
  if (channels.length === 0) {
    throw new HttpsError("failed-precondition", "No hay canales habilitados para multiposting.");
  }

  const now = FieldValue.serverTimestamp();
  const publishBatchId = Date.now().toString(36);
  const publications = channels.map((selection) => {
    const channel = selection.channel;
    const channelMeta = CHANNEL_CATALOG[channel];
    const costEur = resolveChannelCostEur(channel, selection.costOverrideEur, companySettings);
    const trackingUrl = buildTrackingUrl(offerId, channel);
    return {
      channel,
      channelLabel: channelMeta.label,
      trackingUrl,
      publicationId: `${offerId}_${channel}_${publishBatchId}`,
      externalPostId: `mvp_${channel}_${offerId}_${publishBatchId}`,
      costEur,
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
        channelLabel: publication.channelLabel,
        status: "published",
        trackingUrl: publication.trackingUrl,
        externalPostId: publication.externalPostId,
        attributionKey: publication.channel,
        cost: { amount: publication.costEur, currency: "EUR", model: "flat_posting" },
        publishedBy: actorUid,
        publishedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
  }

  const offerUpdates: Record<string, unknown> = {
    multiposting_enabled_channels: publications.map((row) => row.channel),
    multiposting_updated_at: now,
    updated_at: now,
  };
  for (const publication of publications) {
    offerUpdates[`multiposting.channels.${publication.channel}`] = {
      status: "published",
      channelLabel: publication.channelLabel,
      trackingUrl: publication.trackingUrl,
      externalPostId: publication.externalPostId,
      attributionKey: publication.channel,
      cost: { amount: publication.costEur, currency: "EUR", model: "flat_posting" },
      publishedBy: actorUid,
      publishedAt: now,
    };
  }
  batch.set(offerRef, offerUpdates, { merge: true });

  await batch.commit();

  const totalEstimatedCostEur = publications.reduce((acc, p) => acc + p.costEur, 0);
  return {
    ok: true,
    offerId,
    companyId,
    channels: publications.map((row) => ({
      channel: row.channel,
      channelLabel: row.channelLabel,
      trackingUrl: row.trackingUrl,
      status: "published",
      estimatedCostEur: row.costEur,
    })),
    totalEstimatedCostEur: Number(totalEstimatedCostEur.toFixed(2)),
  };
});
