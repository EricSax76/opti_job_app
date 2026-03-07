const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");
const { assertCamelCaseResponse } = require("./helpers/contractAssertions.js");

const { processDataRequest, exportCandidateData } = require("../lib/index.js");

const db = admin.firestore();

function id(prefix) {
  const now = Date.now();
  const random = Math.random().toString(16).slice(2, 10);
  return `${prefix}_${now}_${random}`;
}

function authContext(uid) {
  return {
    auth: {
      uid,
      token: { uid },
    },
  };
}

function utcDateKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
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
  "E2E Compliance Observability: processDataRequest exitoso actualiza SLA y dashboard diario",
  { timeout: 20_000 },
  async () => {
    const companyUid = id("comp");
    const candidateUid = id("cand");
    const requestId = id("req");
    const now = admin.firestore.Timestamp.now();
    const dueAt = new admin.firestore.Timestamp(
      now.seconds + 5 * 24 * 3600,
      now.nanoseconds,
    );

    await db.collection("dataRequests").doc(requestId).set({
      candidateUid,
      companyId: companyUid,
      type: "access",
      status: "pending",
      description: "Solicitud de acceso E2E",
      createdAt: now,
      dueAt,
    });

    const result = await processDataRequest.run(
      {
        requestId,
        status: "completed",
        response: "Reporte entregado.",
      },
      authContext(companyUid),
    );
    assertCamelCaseResponse(result, { path: "processDataRequest.successA" });
    assert.equal(result.success, true);

    const processedDoc = await db.collection("dataRequests").doc(requestId).get();
    assert.equal(processedDoc.get("status"), "completed");
    assert.equal(processedDoc.get("processedBy"), companyUid);
    assert.equal(processedDoc.get("resolvedWithinSla"), true);
    assert.equal(processedDoc.get("slaBreached"), false);
    assert.ok(typeof processedDoc.get("requestAgeMs") === "number");

    const dailyDocId = `${companyUid}:${utcDateKey()}`;
    const dailyDoc = await db.collection("complianceOpsDaily").doc(dailyDocId).get();
    assert.equal(dailyDoc.exists, true);
    assert.equal(dailyDoc.get("operations.processDataRequest.invocations"), 1);
    assert.equal(dailyDoc.get("operations.processDataRequest.successCount"), 1);
    assert.equal(dailyDoc.get("operations.processDataRequest.errorCount"), 0);
    assert.equal(dailyDoc.get("sla.completedCount"), 1);
    assert.equal(dailyDoc.get("sla.completedWithinCount"), 1);
    assert.equal(dailyDoc.get("sla.completedOutsideCount"), 0);

    const events = await db
      .collection("complianceOpsEvents")
      .where("operation", "==", "processDataRequest")
      .where("outcome", "==", "success")
      .where("requestId", "==", requestId)
      .limit(1)
      .get();
    assert.equal(events.empty, false);
    assert.equal(events.docs[0].get("companyId"), companyUid);
    assert.ok(events.docs[0].get("latencyMs") >= 0);
  },
);

test(
  "E2E Compliance Observability: breach de SLA genera alerta diaria",
  { timeout: 20_000 },
  async () => {
    const companyUid = id("comp");
    const candidateUid = id("cand");
    const requestId = id("req");
    const now = admin.firestore.Timestamp.now();
    const dueAtPast = new admin.firestore.Timestamp(
      now.seconds - 2 * 24 * 3600,
      now.nanoseconds,
    );

    await db.collection("dataRequests").doc(requestId).set({
      candidateUid,
      companyId: companyUid,
      type: "deletion",
      status: "pending",
      description: "Solicitud de supresión E2E",
      createdAt: now,
      dueAt: dueAtPast,
    });

    const result = await processDataRequest.run(
      {
        requestId,
        status: "completed",
        response: "Cierre fuera de SLA.",
      },
      authContext(companyUid),
    );
    assertCamelCaseResponse(result, { path: "processDataRequest.successB" });
    assert.equal(result.success, true);

    const processedDoc = await db.collection("dataRequests").doc(requestId).get();
    assert.equal(processedDoc.get("resolvedWithinSla"), false);
    assert.equal(processedDoc.get("slaBreached"), true);

    const dailyDocId = `${companyUid}:${utcDateKey()}`;
    const dailyDoc = await db.collection("complianceOpsDaily").doc(dailyDocId).get();
    assert.equal(dailyDoc.exists, true);
    assert.equal(dailyDoc.get("sla.completedCount"), 1);
    assert.equal(dailyDoc.get("sla.completedOutsideCount"), 1);
    assert.equal(dailyDoc.get("alerts.hasSlaBreaches"), true);
    assert.equal(dailyDoc.get("alerts.slaBreachCount"), 1);
  },
);

test(
  "E2E Compliance Observability: exportCandidateData registra métricas de latencia",
  { timeout: 20_000 },
  async () => {
    const candidateUid = id("cand");
    const companyUid = id("comp");
    const now = admin.firestore.Timestamp.now();

    await Promise.all([
      db
        .collection("candidates")
        .doc(candidateUid)
        .collection("curriculum")
        .doc("main")
        .set({
          title: "Perfil principal",
          updatedAt: now,
        }),
      db.collection("applications").doc(id("app")).set({
        candidateId: candidateUid,
        companyId: companyUid,
        status: "pending",
      }),
      db.collection("consentRecords").doc(id("cons")).set({
        candidateUid,
        companyId: companyUid,
        type: "ai_granular",
        granted: true,
      }),
      db.collection("candidateNotes").doc(id("note")).set({
        candidateUid,
        companyId: companyUid,
        note: "nota interna",
      }),
      db.collection("dataRequests").doc(id("req")).set({
        candidateUid,
        companyId: companyUid,
        type: "access",
        status: "pending",
        description: "Solicitud previa",
      }),
    ]);

    const payload = await exportCandidateData.run({}, authContext(candidateUid));
    assertCamelCaseResponse(payload, {
      path: "exportCandidateData",
      deep: false,
    });
    assert.equal(payload.candidateUid, candidateUid);
    assert.ok(payload.metadata?.applicationsCount >= 1);

    const globalDocId = `global:${utcDateKey()}`;
    const globalDoc = await db.collection("complianceOpsDaily").doc(globalDocId).get();
    assert.equal(globalDoc.exists, true);
    assert.equal(globalDoc.get("operations.exportCandidateData.invocations"), 1);
    assert.equal(globalDoc.get("operations.exportCandidateData.successCount"), 1);
    assert.equal(globalDoc.get("operations.exportCandidateData.errorCount"), 0);
    assert.ok(globalDoc.get("operations.exportCandidateData.totalLatencyMs") >= 0);

    const events = await db
      .collection("complianceOpsEvents")
      .where("operation", "==", "exportCandidateData")
      .where("outcome", "==", "success")
      .where("actorUid", "==", candidateUid)
      .limit(1)
      .get();
    assert.equal(events.empty, false);
    assert.ok(events.docs[0].get("latencyMs") >= 0);
  },
);
