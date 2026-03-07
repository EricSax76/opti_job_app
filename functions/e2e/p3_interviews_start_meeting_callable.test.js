const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");
const { assertAuditLogContract } = require("./helpers/contractAssertions.js");

const { startMeeting } = require("../lib/index.js");

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
  participants = [companyUid, candidateUid],
  status = "scheduled",
}) {
  const now = admin.firestore.Timestamp.now();
  await db.collection("interviews").doc(interviewId).set({
    id: interviewId,
    applicationId: id("app"),
    jobOfferId: id("offer"),
    companyUid,
    candidateUid,
    participants,
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
  "E2E Interviews: participante puede iniciar meeting y se registra auditoría",
  { timeout: 20_000 },
  async () => {
    const interviewId = id("int");
    const companyUid = id("comp");
    const candidateUid = id("cand");
    const meetingLink = "https://meet.google.com/aaa-bbbb-ccc";

    await seedInterview({ interviewId, companyUid, candidateUid });

    await startMeeting.run(
      {
        interviewId,
        meetingLink,
      },
      authContext(companyUid),
    );

    const interviewSnap = await db.collection("interviews").doc(interviewId).get();
    assert.equal(interviewSnap.get("meetingLink"), meetingLink);

    const lastMessage = interviewSnap.get("lastMessage");
    assert.ok(lastMessage);
    assert.equal(lastMessage.content, "Videollamada iniciada");
    assert.equal(lastMessage.senderUid, "system");
    assert.ok(lastMessage.createdAt);

    const messageSnap = await db
      .collection("interviews")
      .doc(interviewId)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(1)
      .get();
    assert.equal(messageSnap.empty, false);
    const message = messageSnap.docs[0].data();
    assert.equal(message.senderUid, "system");
    assert.equal(message.type, "system");
    assert.ok(String(message.content).includes(meetingLink));

    const auditSnap = await db
      .collection("auditLogs")
      .where("action", "==", "interview.startMeeting")
      .where("targetId", "==", interviewId)
      .where("actorUid", "==", companyUid)
      .limit(1)
      .get();
    assert.equal(auditSnap.empty, false);
    const audit = auditSnap.docs[0].data();
    assertAuditLogContract(audit);
    assert.equal(audit.actorRole, "company");
    assert.equal(audit.targetType, "interview");
    assert.equal(audit.companyId, companyUid);
    assert.equal(audit.metadata?.meetingHost, "meet.google.com");
  },
);

test(
  "E2E Interviews: usuario no participante no puede iniciar meeting",
  { timeout: 20_000 },
  async () => {
    const interviewId = id("int");
    const companyUid = id("comp");
    const candidateUid = id("cand");
    const outsiderUid = id("outsider");

    await seedInterview({ interviewId, companyUid, candidateUid });

    await assert.rejects(
      () =>
        startMeeting.run(
          {
            interviewId,
            meetingLink: "https://meet.example.com/blocked",
          },
          authContext(outsiderUid),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );
  },
);

test(
  "E2E Interviews: no se puede iniciar meeting en entrevista cerrada",
  { timeout: 20_000 },
  async () => {
    const interviewId = id("int");
    const companyUid = id("comp");
    const candidateUid = id("cand");

    await seedInterview({
      interviewId,
      companyUid,
      candidateUid,
      status: "completed",
    });

    await assert.rejects(
      () =>
        startMeeting.run(
          {
            interviewId,
            meetingLink: "https://meet.example.com/closed",
          },
          authContext(companyUid),
        ),
      (error) => {
        assert.equal(error?.code, "failed-precondition");
        return true;
      },
    );
  },
);
