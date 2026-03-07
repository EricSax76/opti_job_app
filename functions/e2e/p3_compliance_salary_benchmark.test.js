const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");

const { upsertSalaryBenchmark } = require("../lib/index.js");

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

async function seedRecruiter({
  uid,
  companyId,
  role,
  status = "active",
}) {
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection("recruiters").doc(uid).set({
    uid,
    companyId,
    role,
    status,
    name: `Recruiter ${uid}`,
    email: `${uid}@example.com`,
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
  "E2E Compliance: company owner puede registrar benchmark salarial",
  { timeout: 20_000 },
  async () => {
    const companyId = id("comp");
    const roleKey = "frontend_engineer";

    const result = await upsertSalaryBenchmark.run(
      {
        companyId,
        roleKey,
        maleAverageSalary: 52000,
        femaleAverageSalary: 50000,
        nonBinaryAverageSalary: 51000,
        sampleSize: 24,
      },
      authContext(companyId),
    );

    assert.equal(result.ok, true);
    assert.equal(result.companyId, companyId);
    assert.equal(result.roleKey, roleKey);
    assert.equal(result.updatedRows, 3);

    const snapshot = await db
      .collection("salaryBenchmarks")
      .where("companyId", "==", companyId)
      .where("roleKey", "==", roleKey)
      .get();
    assert.equal(snapshot.size, 3);

    const genders = new Set(snapshot.docs.map((doc) => doc.get("gender")));
    assert.deepEqual(genders, new Set(["male", "female", "non_binary"]));
  },
);

test(
  "E2E Compliance: recruiter admin activo puede registrar benchmark",
  { timeout: 20_000 },
  async () => {
    const companyId = id("comp");
    const recruiterUid = id("rec_admin");
    await seedRecruiter({
      uid: recruiterUid,
      companyId,
      role: "admin",
      status: "active",
    });

    const result = await upsertSalaryBenchmark.run(
      {
        companyId,
        title: "Data Scientist",
        femaleAverageSalary: 61000,
        sampleSize: 12,
      },
      authContext(recruiterUid),
    );

    assert.equal(result.ok, true);
    assert.equal(result.updatedRows, 1);

    const benchmarkId = `${companyId}_data_scientist_female`;
    const benchmarkDoc = await db
      .collection("salaryBenchmarks")
      .doc(benchmarkId)
      .get();
    assert.equal(benchmarkDoc.exists, true);
    assert.equal(benchmarkDoc.get("averageSalary"), 61000);
    assert.equal(benchmarkDoc.get("sampleSize"), 12);
  },
);

test(
  "E2E Compliance: recruiter viewer no puede registrar benchmark",
  { timeout: 20_000 },
  async () => {
    const companyId = id("comp");
    const recruiterUid = id("rec_viewer");
    await seedRecruiter({
      uid: recruiterUid,
      companyId,
      role: "viewer",
      status: "active",
    });

    await assert.rejects(
      () =>
        upsertSalaryBenchmark.run(
          {
            companyId,
            roleKey: "backend_engineer",
            maleAverageSalary: 64000,
          },
          authContext(recruiterUid),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );
  },
);
