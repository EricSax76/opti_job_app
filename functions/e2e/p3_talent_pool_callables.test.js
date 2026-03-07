const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");

const { addToPool, requestConsent } = require("../lib/index.js");

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
  "E2E Talent: addToPool añade miembro y cuando falta consentimiento requestConsent crea notificación",
  { timeout: 20_000 },
  async () => {
    const actorUid = id("rec");
    const companyId = id("comp");
    const poolId = id("pool");
    const candidateUid = id("cand");

    await db.collection("talentPools").doc(poolId).set({
      companyId,
      name: "Pool principal",
      memberCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const addResult = await addToPool.run(
      {
        poolId,
        candidateUid,
        tags: ["priority", "frontend"],
        source: "manual",
      },
      authContext(actorUid),
    );

    assert.equal(addResult.success, true);
    assert.equal(addResult.consentRequired, true);

    const memberSnap = await db
      .collection("talentPools")
      .doc(poolId)
      .collection("members")
      .doc(candidateUid)
      .get();
    assert.equal(memberSnap.exists, true);
    assert.equal(memberSnap.get("candidateUid"), candidateUid);
    assert.equal(memberSnap.get("addedBy"), actorUid);
    assert.deepEqual(memberSnap.get("tags"), ["priority", "frontend"]);
    assert.equal(memberSnap.get("consentGiven"), false);

    const poolAfterAdd = await db.collection("talentPools").doc(poolId).get();
    assert.equal(poolAfterAdd.get("memberCount"), 1);

    const consentResult = await requestConsent.run(
      {
        candidateUid,
        poolId,
      },
      authContext(actorUid),
    );
    assert.equal(consentResult.success, true);

    const notifications = await db
      .collection("notifications")
      .where("userId", "==", candidateUid)
      .where("poolId", "==", poolId)
      .where("type", "==", "consent_request")
      .limit(1)
      .get();
    assert.equal(notifications.empty, false);
  },
);

test(
  "E2E Talent: addToPool reutiliza consentimiento existente cuando está vigente",
  { timeout: 20_000 },
  async () => {
    const actorUid = id("rec");
    const companyId = id("comp");
    const poolWithConsent = id("pool_existing");
    const targetPool = id("pool_target");
    const candidateUid = id("cand");

    await Promise.all([
      db.collection("talentPools").doc(poolWithConsent).set({
        companyId,
        name: "Pool con consentimiento",
        memberCount: 1,
      }),
      db.collection("talentPools").doc(targetPool).set({
        companyId,
        name: "Pool destino",
        memberCount: 0,
      }),
    ]);

    const now = admin.firestore.Timestamp.now();
    const consentExpiresAt = new admin.firestore.Timestamp(
      now.seconds + 7 * 24 * 3600,
      now.nanoseconds,
    );
    const consentAt = new admin.firestore.Timestamp(
      now.seconds - 24 * 3600,
      now.nanoseconds,
    );

    await db
      .collection("talentPools")
      .doc(poolWithConsent)
      .collection("members")
      .doc(candidateUid)
      .set({
        candidateUid,
        consentGiven: true,
        consentAt,
        consentExpiresAt,
      });

    const addResult = await addToPool.run(
      {
        poolId: targetPool,
        candidateUid,
        tags: ["carry-over-consent"],
      },
      authContext(actorUid),
    );

    assert.equal(addResult.success, true);
    assert.equal(addResult.consentRequired, false);

    const targetMember = await db
      .collection("talentPools")
      .doc(targetPool)
      .collection("members")
      .doc(candidateUid)
      .get();
    assert.equal(targetMember.exists, true);
    assert.equal(targetMember.get("consentGiven"), true);
    assert.ok(targetMember.get("consentAt"));
    assert.ok(targetMember.get("consentExpiresAt"));
  },
);
