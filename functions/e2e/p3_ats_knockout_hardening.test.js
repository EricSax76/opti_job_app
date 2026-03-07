const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");
const {
  assertCamelCaseResponse,
  assertAuditLogContract,
} = require("./helpers/contractAssertions.js");

const { evaluateKnockoutQuestions, grantAiConsent } = require("../lib/index.js");

const db = admin.firestore();

function id(prefix) {
  const now = Date.now();
  const random = Math.random().toString(16).slice(2, 10);
  return `${prefix}_${now}_${random}`;
}

function authContext(uid) {
  return {
    uid,
    token: { uid },
  };
}

function callableRequest(data, uid) {
  return {
    data,
    auth: authContext(uid),
  };
}

async function seedOffer({
  offerId,
  companyUid,
  knockoutQuestions = [
    {
      id: "q1",
      type: "boolean",
      question: "Tienes permiso de trabajo vigente",
      requiredAnswer: true,
    },
  ],
}) {
  await db.collection("jobOffers").doc(offerId).set({
    id: offerId,
    title: "Oferta QA",
    company_uid: companyUid,
    knockoutQuestions,
    pipelineStages: [
      { id: "stage_new", name: "Nuevo", type: "new" },
      { id: "stage_screen", name: "Screening", type: "screening" },
    ],
  });
}

async function seedApplication({
  applicationId,
  offerId,
  candidateUid,
  companyUid,
}) {
  const now = admin.firestore.Timestamp.now();
  await db.collection("applications").doc(applicationId).set({
    id: applicationId,
    job_offer_id: offerId,
    candidate_uid: candidateUid,
    company_uid: companyUid,
    status: "pending",
    submitted_at: now,
    updated_at: now,
  });
}

before(() => {
  assert.ok(
    process.env.FIRESTORE_EMULATOR_HOST,
    "FIRESTORE_EMULATOR_HOST no está definido. Ejecuta con Firebase Emulator.",
  );
});

after(async () => {
  await Promise.all(admin.apps.map((app) => app.delete()));
});

test(
  "E2E ATS: consentimiento faltante marca estado observable blocked_consent",
  { timeout: 20_000 },
  async () => {
    const companyUid = id("comp");
    const candidateUid = id("cand");
    const offerId = id("offer");
    const applicationId = id("app");

    await seedOffer({ offerId, companyUid });
    await seedApplication({
      applicationId,
      offerId,
      candidateUid,
      companyUid,
    });

    const result = await evaluateKnockoutQuestions.run(
      callableRequest(
        {
          applicationId,
          responses: { q1: true },
        },
        candidateUid,
      ),
    );
    assertCamelCaseResponse(result, { path: "evaluateKnockoutQuestions.blockedConsent" });

    assert.equal(result.success, false);
    assert.equal(result.consentRequired, true);
    assert.equal(result.requiredScope, "ai_test");

    const appSnap = await db.collection("applications").doc(applicationId).get();
    assert.equal(appSnap.get("aiConsentRequired"), true);
    assert.equal(appSnap.get("requiresHumanReview"), true);
    assert.equal(appSnap.get("knockoutEvaluationStatus"), "blocked_consent");
    assert.equal(appSnap.get("knockoutEvaluationNeedsAttention"), true);
    assert.equal(appSnap.get("knockoutEvaluationAttempts"), 1);
    assert.ok(appSnap.get("knockoutEvaluationLastAttemptAt"));
  },
);

test(
  "E2E ATS: con consentimiento válido y respuestas correctas la evaluación completa en éxito",
  { timeout: 20_000 },
  async () => {
    const companyUid = id("comp");
    const candidateUid = id("cand");
    const offerId = id("offer");
    const applicationId = id("app");

    await Promise.all([
      db.collection("companies").doc(companyUid).set({
        uid: companyUid,
        role: "company",
        name: "Company ATS",
      }),
      seedOffer({ offerId, companyUid }),
      seedApplication({
        applicationId,
        offerId,
        candidateUid,
        companyUid,
      }),
    ]);

    const consent = await grantAiConsent.run(
      callableRequest(
        {
          companyId: companyUid,
          type: "ai_granular",
          scope: ["ai_test"],
          consentTextVersion: "2026.1",
          consentText: "Acepto evaluación técnica asistida por IA.",
        },
        candidateUid,
      ),
    );
    assertCamelCaseResponse(consent, { path: "grantAiConsent" });
    assert.equal(consent.ok, true);

    const result = await evaluateKnockoutQuestions.run(
      callableRequest(
        {
          applicationId,
          responses: { q1: true },
        },
        candidateUid,
      ),
    );
    assertCamelCaseResponse(result, { path: "evaluateKnockoutQuestions.success" });

    assert.equal(result.success, true);
    assert.equal(result.knockoutPassed, true);

    const appSnap = await db.collection("applications").doc(applicationId).get();
    assert.equal(appSnap.get("knockoutPassed"), true);
    assert.equal(appSnap.get("requiresHumanReview"), false);
    assert.equal(appSnap.get("aiConsentRequired"), false);
    assert.equal(appSnap.get("aiConsentStatus"), "granted");
    assert.equal(appSnap.get("knockoutEvaluationStatus"), "completed");
    assert.equal(appSnap.get("knockoutEvaluationNeedsAttention"), false);
    assert.equal(appSnap.get("knockoutEvaluationAttempts"), 1);
    assert.ok(appSnap.get("knockoutEvaluationLastAttemptAt"));
  },
);

test(
  "E2E ATS: fallo técnico persiste estado failed y audit log",
  { timeout: 20_000 },
  async () => {
    const companyUid = id("comp");
    const candidateUid = id("cand");
    const missingOfferId = id("offer_missing");
    const applicationId = id("app");

    await seedApplication({
      applicationId,
      offerId: missingOfferId,
      candidateUid,
      companyUid,
    });

    await assert.rejects(
      () =>
        evaluateKnockoutQuestions.run(
          callableRequest(
            {
              applicationId,
              responses: { q1: true },
            },
            candidateUid,
          ),
        ),
      (error) => {
        assert.equal(error?.code, "not-found");
        return true;
      },
    );

    const appSnap = await db.collection("applications").doc(applicationId).get();
    assert.equal(appSnap.get("knockoutEvaluationStatus"), "failed");
    assert.equal(appSnap.get("knockoutEvaluationNeedsAttention"), true);
    assert.equal(appSnap.get("knockoutEvaluationLastErrorCode"), "not-found");
    assert.equal(appSnap.get("requiresHumanReview"), true);
    assert.equal(appSnap.get("knockoutEvaluationAttempts"), 1);
    assert.ok(appSnap.get("knockoutEvaluationLastAttemptAt"));

    const auditSnap = await db
      .collection("auditLogs")
      .where("action", "==", "knockout_evaluation_failed")
      .where("targetId", "==", applicationId)
      .where("actorUid", "==", candidateUid)
      .limit(1)
      .get();
    assert.equal(auditSnap.empty, false);
    const audit = auditSnap.docs[0].data();
    assertAuditLogContract(audit);
    assert.equal(audit.action, "knockout_evaluation_failed");
    assert.equal(audit.actorRole, "candidate");
    assert.equal(audit.targetType, "application");
    assert.equal(audit.targetId, applicationId);
    assert.equal(audit.metadata?.errorCode, "not-found");
  },
);

test(
  "E2E ATS: intento sin permisos no altera candidatura objetivo",
  { timeout: 20_000 },
  async () => {
    const companyUid = id("comp");
    const candidateUid = id("cand_owner");
    const outsiderUid = id("cand_outsider");
    const offerId = id("offer");
    const applicationId = id("app");

    await seedOffer({ offerId, companyUid });
    await seedApplication({
      applicationId,
      offerId,
      candidateUid,
      companyUid,
    });

    await assert.rejects(
      () =>
        evaluateKnockoutQuestions.run(
          callableRequest(
            {
              applicationId,
              responses: { q1: true },
            },
            outsiderUid,
          ),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );

    const appSnap = await db.collection("applications").doc(applicationId).get();
    assert.equal(appSnap.get("knockoutEvaluationStatus"), undefined);
    assert.equal(appSnap.get("knockoutEvaluationAttempts"), undefined);
    assert.equal(appSnap.get("requiresHumanReview"), undefined);

    const auditSnap = await db
      .collection("auditLogs")
      .where("action", "==", "knockout_evaluation_failed")
      .where("targetId", "==", applicationId)
      .where("actorUid", "==", outsiderUid)
      .limit(1)
      .get();
    assert.equal(auditSnap.empty, false);
    const audit = auditSnap.docs[0].data();
    assertAuditLogContract(audit);
    assert.equal(audit.metadata?.errorCode, "permission-denied");
    assert.equal(audit.metadata?.applicationSignalWritten, false);
  },
);
