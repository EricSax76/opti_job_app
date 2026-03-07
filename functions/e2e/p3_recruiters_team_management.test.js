const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");

const {
  createInvitation,
  acceptInvitation,
  updateRecruiterRole,
  removeRecruiter,
} = require("../lib/index.js");

const db = admin.firestore();
const auth = admin.auth();

function id(prefix) {
  const now = Date.now();
  const random = Math.random().toString(16).slice(2, 10);
  return `${prefix}_${now}_${random}`;
}

function authContext(uid, email) {
  return {
    auth: {
      uid,
      token: {
        uid,
        email,
        firebase: {
          sign_in_second_factor: "sms",
        },
      },
    },
  };
}

async function ensureAuthUser(uid, email) {
  try {
    await auth.createUser({ uid, email });
  } catch (error) {
    if (error?.code !== "auth/uid-already-exists") throw error;
  }
}

async function seedRecruiter({
  uid,
  companyId,
  role,
  status = "active",
  name,
  email,
}) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection("recruiters").doc(uid).set({
    uid,
    companyId,
    role,
    status,
    name,
    email,
    createdAt: now,
    updatedAt: now,
  });
}

before(() => {
  assert.ok(
    process.env.FIRESTORE_EMULATOR_HOST,
    "FIRESTORE_EMULATOR_HOST no está definido. Ejecuta con Firebase Emulator.",
  );
  assert.ok(
    process.env.FIREBASE_AUTH_EMULATOR_HOST,
    "FIREBASE_AUTH_EMULATOR_HOST no está definido. Incluye emulator auth.",
  );
});

after(async () => {
  await Promise.all(admin.apps.map((app) => app.delete()));
});

test(
  "E2E Recruiters: admin crea invitación, freelance la acepta y admin gestiona rol/baja",
  { timeout: 30_000 },
  async () => {
    const companyId = id("comp");
    const adminUid = id("admin");
    const freelanceUid = id("free");
    const adminEmail = `${adminUid}@example.com`;
    const freelanceEmail = `${freelanceUid}@example.com`;

    await Promise.all([
      ensureAuthUser(adminUid, adminEmail),
      ensureAuthUser(freelanceUid, freelanceEmail),
      seedRecruiter({
        uid: adminUid,
        companyId,
        role: "admin",
        status: "active",
        name: "Admin Team",
        email: adminEmail,
      }),
      // Perfil recruiter autónomo sin empresa asociada.
      seedRecruiter({
        uid: freelanceUid,
        companyId: "",
        role: "recruiter",
        status: "active",
        name: "Freelance Recruiter",
        email: freelanceEmail,
      }),
    ]);

    const invite = await createInvitation.run(
      { role: "recruiter", email: freelanceEmail },
      authContext(adminUid, adminEmail),
    );

    assert.ok(invite.code);
    assert.equal(String(invite.code).length, 6);

    const invitationSnap = await db
      .collection("invitations")
      .doc(String(invite.code))
      .get();
    assert.equal(invitationSnap.exists, true);
    assert.equal(invitationSnap.get("companyId"), companyId);
    assert.equal(invitationSnap.get("role"), "recruiter");
    assert.equal(invitationSnap.get("status"), "pending");

    const accept = await acceptInvitation.run(
      { code: String(invite.code), name: "Freelance Joined" },
      authContext(freelanceUid, freelanceEmail),
    );
    assert.equal(accept.success, true);

    const invitationAfterAccept = await db
      .collection("invitations")
      .doc(String(invite.code))
      .get();
    assert.equal(invitationAfterAccept.get("status"), "accepted");
    assert.equal(invitationAfterAccept.get("usedBy"), freelanceUid);

    const recruiterAfterAccept = await db
      .collection("recruiters")
      .doc(freelanceUid)
      .get();
    assert.equal(recruiterAfterAccept.get("companyId"), companyId);
    assert.equal(recruiterAfterAccept.get("status"), "active");
    assert.equal(recruiterAfterAccept.get("role"), "recruiter");

    const roleUpdate = await updateRecruiterRole.run(
      { targetUid: freelanceUid, newRole: "hiring_manager" },
      authContext(adminUid, adminEmail),
    );
    assert.equal(roleUpdate.success, true);

    const recruiterAfterRoleUpdate = await db
      .collection("recruiters")
      .doc(freelanceUid)
      .get();
    assert.equal(recruiterAfterRoleUpdate.get("role"), "hiring_manager");

    const remove = await removeRecruiter.run(
      { targetUid: freelanceUid },
      authContext(adminUid, adminEmail),
    );
    assert.equal(remove.success, true);

    const recruiterAfterRemove = await db
      .collection("recruiters")
      .doc(freelanceUid)
      .get();
    assert.equal(recruiterAfterRemove.get("status"), "disabled");
  },
);

test(
  "E2E Recruiters: miembro no admin no puede crear invitación, cambiar rol ni deshabilitar",
  { timeout: 30_000 },
  async () => {
    const companyId = id("comp");
    const adminUid = id("admin");
    const memberUid = id("member");
    const targetUid = id("target");
    const adminEmail = `${adminUid}@example.com`;
    const memberEmail = `${memberUid}@example.com`;
    const targetEmail = `${targetUid}@example.com`;

    await Promise.all([
      ensureAuthUser(adminUid, adminEmail),
      ensureAuthUser(memberUid, memberEmail),
      ensureAuthUser(targetUid, targetEmail),
      seedRecruiter({
        uid: adminUid,
        companyId,
        role: "admin",
        status: "active",
        name: "Admin Team",
        email: adminEmail,
      }),
      seedRecruiter({
        uid: memberUid,
        companyId,
        role: "recruiter",
        status: "active",
        name: "Member Recruiter",
        email: memberEmail,
      }),
      seedRecruiter({
        uid: targetUid,
        companyId,
        role: "viewer",
        status: "active",
        name: "Target Recruiter",
        email: targetEmail,
      }),
    ]);

    await assert.rejects(
      () =>
        createInvitation.run(
          { role: "viewer" },
          authContext(memberUid, memberEmail),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );

    await assert.rejects(
      () =>
        updateRecruiterRole.run(
          { targetUid, newRole: "auditor" },
          authContext(memberUid, memberEmail),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );

    await assert.rejects(
      () =>
        removeRecruiter.run(
          { targetUid },
          authContext(memberUid, memberEmail),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );
  },
);
