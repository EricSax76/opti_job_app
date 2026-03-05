import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import {
  FirestoreDoc,
  JsonDoc,
  DEFAULT_CHANNEL_COST_EUR,
  asRecord,
  average,
  toSafeRate,
  pickDate,
  inRange,
  dedupeDocs,
  normalizeSource,
  parseNumber,
  round2,
  daysBetween,
  computePipelineMetrics,
  annualizedSalaryValue,
  computeSourceEffectiveness,
  computeRecruiterMetrics,
  monthBounds,
} from "./utils/analyticsUtils";

export const computeMonthlyAnalytics = functions.region("europe-west1").pubsub.schedule("0 0 1 * *").onRun(async () => {
  const db = admin.firestore();
  const now = new Date();
  const targetMonth = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));
  const { start, end, period } = monthBounds(targetMonth);

  const companies = await db.collection("companies").get();
  for (const companyDoc of companies.docs) {
    const companyId = companyDoc.id;

    const [offersSnake, offersCamel, appsSnake, appsCamel, evaluations, multipostingPublications] = await Promise.all([
      db.collection("jobOffers").where("company_uid", "==", companyId).get(),
      db.collection("jobOffers").where("companyUid", "==", companyId).get(),
      db.collection("applications").where("company_uid", "==", companyId).get(),
      db.collection("applications").where("companyUid", "==", companyId).get(),
      db.collection("evaluations").where("companyId", "==", companyId).get(),
      db.collection("multipostingPublications").where("companyId", "==", companyId).get(),
    ]);

    const offerDocs = dedupeDocs(offersSnake, offersCamel);
    const applicationDocs = dedupeDocs(appsSnake, appsCamel);
    const evaluationDocs = evaluations.docs as FirestoreDoc[];

    const offers = offerDocs.map((doc) => doc.data() as Record<string, unknown>);
    const applications: Array<Record<string, unknown>> = applicationDocs.map((doc) => ({
      id: doc.id,
      ...(doc.data() as Record<string, unknown>),
    }));
    const evaluationsData = evaluationDocs.map((doc) => doc.data() as Record<string, unknown>);
    const publicationData = multipostingPublications.docs.map(
      (doc) => doc.data() as Record<string, unknown>,
    );

    const offersInPeriod = offers.filter((offer) =>
      inRange(pickDate(offer, ["created_at", "createdAt"]), start, end),
    );

    const applicationsInPeriod = applications.filter((app) =>
      inRange(pickDate(app, ["submitted_at", "submittedAt", "created_at", "createdAt"]), start, end),
    );

    const startedApplicationsInPeriod = applications.filter((app) =>
      inRange(pickDate(app, ["application_started_at", "applicationStartedAt"]), start, end),
    ).length;

    const evaluationsInPeriod = evaluationsData.filter((evaluation) =>
      inRange(pickDate(evaluation, ["createdAt"]), start, end),
    );

    const publicationsInPeriod = publicationData.filter((publication) =>
      inRange(pickDate(publication, ["publishedAt", "updatedAt", "createdAt"]), start, end),
    );

    const applicationsById = new Map(
      applications.map((app) => [String(app.id), app as Record<string, unknown>]),
    );
    const offersById = new Map<string, JsonDoc>();
    for (const offerDoc of offerDocs) {
      const offer = offerDoc.data() as JsonDoc;
      const offerId = String(offer.id ?? offerDoc.id).trim();
      if (offerId.length === 0) continue;
      offersById.set(offerId, offer);
    }

    const timeToHireDays: number[] = [];
    for (const app of applications) {
      const status = String(app.status ?? "").toLowerCase();
      if (status !== "hired") continue;
      const hiredAt = pickDate(app, ["hired_at", "hiredAt", "updated_at", "updatedAt"]);
      if (!inRange(hiredAt, start, end)) continue;
      const submittedAt = pickDate(app, ["submitted_at", "submittedAt", "created_at", "createdAt"]);
      if (submittedAt == null || hiredAt == null) continue;
      timeToHireDays.push(daysBetween(submittedAt, hiredAt));
    }

    const timeToFillDays: number[] = [];
    const hiredByOffer = new Map<string, Date[]>();
    for (const app of applications) {
      if (String(app.status ?? "").toLowerCase() !== "hired") continue;
      const jobOfferId = String(app.job_offer_id ?? app.jobOfferId ?? "").trim();
      const hiredAt = pickDate(app, ["hired_at", "hiredAt", "updated_at", "updatedAt"]);
      if (jobOfferId.length === 0 || hiredAt == null) continue;
      const list = hiredByOffer.get(jobOfferId) ?? [];
      list.push(hiredAt);
      hiredByOffer.set(jobOfferId, list);
    }

    for (const offerDoc of offerDocs) {
      const offer = offerDoc.data() as Record<string, unknown>;
      const offerCreatedAt = pickDate(offer, ["created_at", "createdAt"]);
      if (!inRange(offerCreatedAt, start, end)) continue;
      const offerId = String(offer.id ?? offerDoc.id).trim();
      if (offerId.length === 0) continue;
      const hiredDates = hiredByOffer.get(offerId);
      if (hiredDates == null || hiredDates.length == 0 || offerCreatedAt == null) continue;
      hiredDates.sort((a, b) => a.getTime() - b.getTime());
      timeToFillDays.push(daysBetween(offerCreatedAt, hiredDates[0]));
    }

    const applicationsReceived = applicationsInPeriod.length;
    const startCount = startedApplicationsInPeriod > 0 ? startedApplicationsInPeriod : applicationsReceived;

    const hiredApplicationsInPeriod = applications.filter((app) =>
      String(app.status ?? "").toLowerCase() === "hired" &&
      inRange(pickDate(app, ["hired_at", "hiredAt", "updated_at", "updatedAt"]), start, end),
    );

    const spendBySourceEur = new Map<string, number>();
    for (const publication of publicationsInPeriod) {
      const source = normalizeSource(publication.channel ?? publication.attributionKey);
      const costRecord = asRecord(publication.cost);
      const explicitCost = parseNumber(
        costRecord?.amount ?? publication.costEur ?? publication.cost_amount,
      );
      const fallbackCost = DEFAULT_CHANNEL_COST_EUR[source] ?? 0;
      const cost = explicitCost ?? fallbackCost;
      if (cost <= 0) continue;
      spendBySourceEur.set(source, round2((spendBySourceEur.get(source) ?? 0) + cost));
    }

    const hireValueBySourceEur = new Map<string, number>();
    for (const app of hiredApplicationsInPeriod) {
      const source = normalizeSource(app.source_channel ?? app.sourceChannel ?? app.source);
      const offerId = String(app.job_offer_id ?? app.jobOfferId ?? "").trim();
      const offer = offerId ? offersById.get(offerId) : undefined;
      const annualValue = annualizedSalaryValue(offer);
      hireValueBySourceEur.set(
        source,
        round2((hireValueBySourceEur.get(source) ?? 0) + annualValue),
      );
    }

    const sourceEffectiveness = computeSourceEffectiveness({
      applicationsInPeriod,
      hiredApplicationsInPeriod,
      spendBySourceEur,
      hireValueBySourceEur,
    });

    const totalMultipostingSpendEur = round2(
      [...spendBySourceEur.values()].reduce((acc, value) => acc + value, 0),
    );
    const totalAttributedHireValueEur = round2(
      [...hireValueBySourceEur.values()].reduce((acc, value) => acc + value, 0),
    );
    const overallChannelRoi =
      totalMultipostingSpendEur > 0
        ? round2((totalAttributedHireValueEur - totalMultipostingSpendEur) / totalMultipostingSpendEur)
        : 0;

    const metrics = {
      offersPublished: offersInPeriod.length,
      applicationsReceived,
      applicationCompletionRate: toSafeRate(applicationsReceived, startCount),
      averageTimeToHire: average(timeToHireDays),
      averageTimeToFill: average(timeToFillDays),
      pipelineConversionRates: computePipelineMetrics(applicationsInPeriod),
      sourceEffectiveness,
      totalMultipostingSpendEur,
      totalAttributedHireValueEur,
      overallChannelRoi,
      recruiterMetrics: computeRecruiterMetrics(evaluationsInPeriod, applicationsById),
    };

    await Promise.all([
      db
        .collection("analytics")
        .doc(companyId)
        .collection("monthly")
        .doc(period)
        .set({
          companyId,
          period,
          metrics,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
      db.collection("analytics").doc(companyId).set(
        {
          companyId,
          latestPeriod: period,
          metrics,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      ),
    ]);
  }

  console.log(`Computed monthly analytics for ${companies.size} companies (${period}).`);
  return null;
});
