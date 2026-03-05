import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { cosineScore01 } from "../../utils/embeddings";
import { writeAiDecisionLog, writeAuditLog } from "../../utils/aiDecisionLogs";
import {
  ALLOWED_REVIEW_ROLES,
  asFiniteNumber,
  asRecord,
  asStringList,
  asTrimmedString,
  buildExperienceScore,
  buildLocationScore,
  buildSkillCoverage,
  clamp01,
  estimateExperienceYears,
  JsonRecord,
  randomId,
  readSkillNames,
  toScore100,
  WEIGHTS,
} from "./utils/matchingLogic";
import {
  manualNeighborSearch,
  tryFirestoreVectorSearch,
} from "./utils/vectorSearch";
import {
  ensureCandidateEmbedding,
  ensureOfferEmbedding,
  resolveCurriculumDoc,
} from "./utils/embeddingEnsurer";

async function assertRecruiterAccess(
  db: FirebaseFirestore.Firestore,
  actorUid: string,
  companyId: string,
): Promise<"company" | "recruiter"> {
  if (actorUid === companyId) return "company";

  const recruiterDoc = await db.collection("recruiters").doc(actorUid).get();
  if (!recruiterDoc.exists) {
    throw new HttpsError(
      "permission-denied",
      "Solo la empresa o recruiters autorizados pueden revisar matching vectorial.",
    );
  }
  const recruiter = asRecord(recruiterDoc.data());
  const recruiterCompanyId = asTrimmedString(recruiter.companyId);
  const recruiterStatus = asTrimmedString(recruiter.status).toLowerCase();
  const recruiterRole = asTrimmedString(recruiter.role);

  if (
    recruiterCompanyId !== companyId ||
    recruiterStatus !== "active" ||
    !ALLOWED_REVIEW_ROLES.has(recruiterRole)
  ) {
    throw new HttpsError(
      "permission-denied",
      "Tu rol no tiene permisos para evaluar decisiones IA de esta empresa.",
    );
  }
  return "recruiter";
}

async function assertApplicationAccess({
  db,
  actorUid,
  candidateUid,
  companyId,
}: {
  db: FirebaseFirestore.Firestore;
  actorUid: string;
  candidateUid: string;
  companyId: string;
}): Promise<"candidate" | "company" | "recruiter"> {
  if (actorUid === candidateUid) return "candidate";
  const scope = await assertRecruiterAccess(db, actorUid, companyId);
  return scope;
}

export const matchCandidateVector = onCall({ region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const applicationId = asTrimmedString(request.data?.applicationId);
  const limit = Math.max(3, Math.min(25, Number(request.data?.limit ?? 8) || 8));
  if (!applicationId) {
    throw new HttpsError("invalid-argument", "applicationId es obligatorio.");
  }

  const requestId = asTrimmedString(request.data?.requestId) || randomId("req");
  const executionId = randomId("exec");
  const db = admin.firestore();

  const appDoc = await db.collection("applications").doc(applicationId).get();
  if (!appDoc.exists) {
    throw new HttpsError("not-found", "La candidatura indicada no existe.");
  }
  const appData = asRecord(appDoc.data());
  const candidateUid =
    asTrimmedString(appData.candidate_uid) ||
    asTrimmedString(appData.candidateId);
  const companyId =
    asTrimmedString(appData.company_uid) ||
    asTrimmedString(appData.companyUid);
  const jobOfferId =
    asTrimmedString(appData.job_offer_id) ||
    asTrimmedString(appData.jobOfferId);

  if (!candidateUid || !companyId || !jobOfferId) {
    throw new HttpsError(
      "failed-precondition",
      "La candidatura no tiene candidate/company/jobOffer consistente.",
    );
  }

  const actorScope = await assertApplicationAccess({
    db,
    actorUid: request.auth.uid,
    candidateUid,
    companyId,
  });

  const [candidateDoc, offerDoc] = await Promise.all([
    db.collection("candidates").doc(candidateUid).get(),
    db.collection("jobOffers").doc(jobOfferId).get(),
  ]);
  if (!offerDoc.exists) {
    throw new HttpsError("not-found", "La oferta de la candidatura no existe.");
  }

  const candidateData = asRecord(candidateDoc.data());
  const offerData = asRecord(offerDoc.data());
  const curriculumId = asTrimmedString(appData.curriculum_id ?? appData.curriculumId);
  const curriculum = await resolveCurriculumDoc({
    db,
    candidateUid,
    curriculumId,
  });

  const [candidateEmbedding, offerEmbedding] = await Promise.all([
    ensureCandidateEmbedding({
      db,
      candidateUid,
      curriculumId: curriculum.curriculumId,
      candidateData,
      curriculumData: curriculum.data,
    }),
    ensureOfferEmbedding({
      offerRef: offerDoc.ref,
      offerData,
    }),
  ]);

  const vectorNeighborsFromFirestore = await tryFirestoreVectorSearch({
    db,
    queryVector: candidateEmbedding.vector,
    limit,
  });
  const vectorSearchMode = vectorNeighborsFromFirestore
    ? "firestore_vector_query"
    : "manual_cosine_fallback";
  const neighbors = vectorNeighborsFromFirestore ??
    await manualNeighborSearch({
      db,
      queryVector: candidateEmbedding.vector,
      limit,
    });

  const targetSimilarity = cosineScore01(
    candidateEmbedding.vector,
    offerEmbedding.vector,
  );
  const targetRank = neighbors.findIndex((item) => item.offerId === jobOfferId);

  const candidateSkills = [
    ...readSkillNames(candidateData.skills),
    ...readSkillNames(curriculum.data.skills),
    ...readSkillNames(curriculum.data.structuredSkills),
  ];
  const offerRequiredSkills = [
    ...asStringList(offerData.requiredSkills),
    ...asStringList(offerData.skills),
  ];
  const offerPreferredSkills = asStringList(offerData.preferredSkills);

  const skillCoverage = buildSkillCoverage({
    candidateSkills,
    offerRequiredSkills,
    offerPreferredSkills,
  });
  const candidateLocation =
    asTrimmedString(candidateData.location) ||
    asTrimmedString(asRecord(curriculum.data.personal_info).location);
  const offerLocation = [
    asTrimmedString(offerData.location),
    asTrimmedString(offerData.province_name ?? offerData.provinceName),
    asTrimmedString(offerData.municipality_name ?? offerData.municipalityName),
  ].filter(Boolean).join(" - ");
  const locationScore = buildLocationScore({
    candidateLocation,
    offerLocation,
  });
  const candidateExperienceYears = estimateExperienceYears(curriculum.data);
  const requiredYears = asFiniteNumber(
    offerData.experience_years ?? offerData.experienceYears,
  );
  const experienceScore = buildExperienceScore({
    candidateYears: candidateExperienceYears,
    requiredYears,
  });

  const semanticScore = targetSimilarity;
  const finalScore = clamp01(
    (semanticScore * WEIGHTS.semanticWeight) +
    (skillCoverage.score * WEIGHTS.skillsWeight) +
    (locationScore * WEIGHTS.locationWeight) +
    (experienceScore * WEIGHTS.experienceWeight),
  );

  const semanticScore100 = toScore100(semanticScore);
  const skillsScore100 = toScore100(skillCoverage.score);
  const locationScore100 = toScore100(locationScore);
  const experienceScore100 = toScore100(experienceScore);
  const finalScore100 = toScore100(finalScore);
  const comparisonDelta = finalScore100 - skillsScore100;

  const reasons: string[] = [];
  reasons.push(
    `Similitud semántica CV-oferta: ${semanticScore100}/100 (${vectorSearchMode}).`,
  );
  reasons.push(
    `Cobertura de skills: ${skillCoverage.matchedRequired.length}/${offerRequiredSkills.length || 1} requeridas.`,
  );
  if (candidateLocation && offerLocation) {
    reasons.push(`Afinidad geográfica estimada: ${locationScore100}/100.`);
  }
  reasons.push(`Ajuste por experiencia: ${experienceScore100}/100.`);

  const recommendations: string[] = [];
  for (const missing of skillCoverage.missingRequired.slice(0, 3)) {
    recommendations.push(`Reforzar skill requerida: ${missing}.`);
  }
  if (recommendations.length === 0) {
    recommendations.push("Continuar con entrevista técnica para validar profundidad.");
  }

  const explanation =
    `Score vectorial final ${finalScore100}/100 con pesos ` +
    `semantic=${WEIGHTS.semanticWeight}, skills=${WEIGHTS.skillsWeight}, ` +
    `location=${WEIGHTS.locationWeight}, experience=${WEIGHTS.experienceWeight}. ` +
    `Sin uso de reconocimiento emocional ni biométrico.`;

  const now = admin.firestore.FieldValue.serverTimestamp();
  const result = {
    score: finalScore100,
    semanticScore: semanticScore100,
    componentScores: {
      semantic: semanticScore100,
      skills: skillsScore100,
      location: locationScore100,
      experience: experienceScore100,
    },
    weights: WEIGHTS,
    reasons,
    recommendations,
    explanation,
    comparative: {
      skillsOnlyScore: skillsScore100,
      deltaVsSkillsOnly: comparisonDelta,
    },
    vectorSearch: {
      mode: vectorSearchMode,
      targetOfferRank: targetRank >= 0 ? (targetRank + 1) : null,
      neighbors: neighbors.slice(0, 5).map((item) => ({
        offerId: item.offerId,
        title: item.title,
        similarity: toScore100(item.similarity),
      })),
    },
    featuresConsidered: {
      candidateSkills: candidateSkills.length,
      requiredSkills: offerRequiredSkills.length,
      preferredSkills: offerPreferredSkills.length,
      matchedRequiredSkills: skillCoverage.matchedRequired,
      missingRequiredSkills: skillCoverage.missingRequired,
      matchedPreferredSkills: skillCoverage.matchedPreferred,
      candidateLocation,
      offerLocation,
      candidateExperienceYears: Number(candidateExperienceYears.toFixed(2)),
      requiredExperienceYears: requiredYears,
    },
    modelVersion: "vector-matcher-v1",
    model: {
      provider: asTrimmedString(offerEmbedding.model.provider) || asTrimmedString(candidateEmbedding.model.provider) || "unknown",
      version: "v1",
      embeddingModel: asTrimmedString(offerEmbedding.model.model) || asTrimmedString(candidateEmbedding.model.model) || "unknown",
      candidateEmbeddingSource: candidateEmbedding.source,
      offerEmbeddingSource: offerEmbedding.source,
    },
    requestId,
    executionId,
    generatedAt: new Date().toISOString(),
  };

  await appDoc.ref.set({
    aiMatchResult: {
      ...result,
      generatedAt: now,
      reviewedByHuman: false,
    },
    match_score: finalScore100,
    updated_at: now,
    updatedAt: now,
  }, { merge: true });

  const decisionLogId = await writeAiDecisionLog({
    applicationId,
    companyId,
    candidateUid,
    jobOfferId,
    decisionType: "vector_match",
    decisionStatus: "generated",
    score: finalScore100,
    weights: WEIGHTS,
    model: {
      provider: asTrimmedString(result.model.provider) || "unknown",
      model: asTrimmedString(result.model.embeddingModel) || "unknown",
      version: asTrimmedString(result.model.version) || "v1",
      source: asTrimmedString(result.model.offerEmbeddingSource) || "unknown",
    },
    requestId,
    executionId,
    features: result.featuresConsidered as unknown as JsonRecord,
    metadata: {
      vectorSearchMode,
      targetOfferRank: targetRank >= 0 ? (targetRank + 1) : null,
      neighbors: result.vectorSearch.neighbors,
      candidateEmbeddingHash: candidateEmbedding.textHash,
      offerEmbeddingHash: offerEmbedding.textHash,
      comparative: result.comparative,
    },
    actorUid: request.auth.uid,
    actorRole: actorScope,
  });

  await Promise.all([
    appDoc.ref.set({
      aiMatchResult: {
        decisionLogId,
      },
    }, { merge: true }),
    writeAuditLog({
      action: "ai_vector_match_generated",
      actorUid: request.auth.uid,
      actorRole: actorScope,
      targetType: "application",
      targetId: applicationId,
      companyId,
      metadata: {
        requestId,
        executionId,
        decisionLogId,
        score: finalScore100,
        vectorSearchMode,
      },
    }),
  ]);

  return {
    applicationId,
    decisionLogId,
    ...result,
  };
});
