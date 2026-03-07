const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");

const { cancelInterview, completeInterview } = require("../lib/index.js");

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

async function seedInterview({
  interviewId,
  companyUid,
  candidateUid,
  status = "scheduled",
}) {
  const now = admin.firestore.Timestamp.now();
  await db.collection("interviews").doc(interviewId).set({
    id: interviewId,
    applicationId: id("app"),
    jobOfferId: id("offer"),
    companyUid,
    candidateUid,
    participants: [companyUid, candidateUid],
    status,
    createdAt: now,
    updatedAt: now,
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
  "E2E Interviews: participante puede cancelar entrevista activa",
  { timeout: 20_000 },
  async () => {
    const interviewId = id("int");
    const companyUid = id("comp");
    const candidateUid = id("cand");

    await seedInterview({ interviewId, companyUid, candidateUid });

    await cancelInterview.run(
      {
        interviewId,
        reason: "Reagendar por conflicto de agenda",
      },
      authContext(candidateUid),
    );

    const interviewSnap = await db.collection("interviews").doc(interviewId).get();
    assert.equal(interviewSnap.get("status"), "cancelled");

    const messageSnap = await db
      .collection("interviews")
      .doc(interviewId)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();
    assert.equal(messageSnap.empty, false);
    const content = String(messageSnap.docs[0].get("content") ?? "");
    assert.ok(content.includes("Interview cancelled by user"));
    assert.ok(content.includes("Reagendar por conflicto de agenda"));
  },
);

test(
  "E2E Interviews: company owner puede completar entrevista",
  { timeout: 20_000 },
  async () => {
    const interviewId = id("int");
    const companyUid = id("comp");
    const candidateUid = id("cand");

    await seedInterview({ interviewId, companyUid, candidateUid });

    await completeInterview.run(
      {
        interviewId,
        notes: "Entrevista finalizada con evaluación positiva",
      },
      authContext(companyUid),
    );

    const interviewSnap = await db.collection("interviews").doc(interviewId).get();
    assert.equal(interviewSnap.get("status"), "completed");

    const messageSnap = await db
      .collection("interviews")
      .doc(interviewId)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();
    assert.equal(messageSnap.empty, false);
    const content = String(messageSnap.docs[0].get("content") ?? "");
    assert.ok(content.includes("Interview marked as completed"));
    assert.ok(content.includes("evaluación positiva"));
  },
);

test(
  "E2E Interviews: candidato no puede completar entrevista",
  { timeout: 20_000 },
  async () => {
    const interviewId = id("int");
    const companyUid = id("comp");
    const candidateUid = id("cand");

    await seedInterview({ interviewId, companyUid, candidateUid });

    await assert.rejects(
      () =>
        completeInterview.run(
          {
            interviewId,
            notes: "Intento sin permisos",
          },
          authContext(candidateUid),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );
  },
);
