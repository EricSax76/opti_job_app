const assert = require("node:assert/strict");
const { after, before, test } = require("node:test");
const admin = require("firebase-admin");
const {
  assertCamelCaseResponse,
  assertAuditLogContract,
} = require("./helpers/contractAssertions.js");

const {
  createSelectiveDisclosureProof,
  verifySelectiveDisclosureProof,
  revokeSelectiveDisclosureProof,
  startQualifiedOfferSignature,
  confirmQualifiedOfferSignature,
  getQualifiedOfferSignatureStatus,
} = require("../lib/index.js");

const db = admin.firestore();

function authContext(uid) {
  return {
    auth: {
      uid,
      token: { uid },
    },
  };
}

function id(prefix) {
  const now = Date.now();
  const random = Math.random().toString(16).slice(2, 10);
  return `${prefix}_${now}_${random}`;
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
  "E2E ZKP: candidato crea prueba selectiva, empresa verifica y candidato revoca",
  { timeout: 30_000 },
  async () => {
    const candidateUid = id("cand");
    const companyUid = id("comp");
    const applicationId = id("app");
    const jobOfferId = id("offer");
    const credentialId = id("cred");

    await Promise.all([
      db.collection("candidates").doc(candidateUid).set({
        uid: candidateUid,
        role: "candidate",
        name: "Candidate ZKP",
        email: `${candidateUid}@example.com`,
      }),
      db.collection("applications").doc(applicationId).set({
        candidate_uid: candidateUid,
        company_uid: companyUid,
        job_offer_id: jobOfferId,
        status: "pending",
      }),
      db
        .collection("candidates")
        .doc(candidateUid)
        .collection("verifiedCredentials")
        .doc(credentialId)
        .set({
          id: credentialId,
          type: "degree",
          title: "Ingeniería Informática",
          issuer: "UPM",
          verified: true,
          metadata: {
            level: "grado",
            specialty: "software",
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
    ]);

    const createResult = await createSelectiveDisclosureProof.run(
      {
        credentialId,
        claimKey: "type",
        statement: "Prueba de titulación técnica verificada",
        applicationId,
        expiresInMinutes: 30,
      },
      authContext(candidateUid),
    );
    assertCamelCaseResponse(createResult, { path: "createSelectiveDisclosureProof" });

    assert.ok(createResult.proofId);
    assert.ok(createResult.proofToken);
    assert.equal(createResult.disclosureMode, "zkp_selective");

    const proofId = String(createResult.proofId);
    const proofToken = String(createResult.proofToken);
    const proofSnap = await db.collection("credentialProofs").doc(proofId).get();
    assert.equal(proofSnap.exists, true);
    assert.equal(proofSnap.get("candidateUid"), candidateUid);
    assert.equal(proofSnap.get("companyUid"), companyUid);
    assert.equal(proofSnap.get("applicationId"), applicationId);
    assert.equal(proofSnap.get("status"), "active");
    assert.equal(proofSnap.get("disclosureMode"), "zkp_selective");

    const verificationResult = await verifySelectiveDisclosureProof.run(
      {
        proofId,
        proofToken,
      },
      authContext(companyUid),
    );
    assertCamelCaseResponse(verificationResult, { path: "verifySelectiveDisclosureProof" });

    assert.equal(verificationResult.verified, true);
    assert.equal(verificationResult.proofId, proofId);
    assert.equal(verificationResult.candidateUid, candidateUid);
    assert.equal(verificationResult.companyUid, companyUid);
    assert.equal(verificationResult.applicationId, applicationId);
    assert.equal(verificationResult.jobOfferId, jobOfferId);

    const verifiedProofSnap = await db
      .collection("credentialProofs")
      .doc(proofId)
      .get();
    assert.equal(verifiedProofSnap.get("verificationCount"), 1);

    const revokeResult = await revokeSelectiveDisclosureProof.run(
      { proofId },
      authContext(candidateUid),
    );
    assertCamelCaseResponse(revokeResult, { path: "revokeSelectiveDisclosureProof" });
    assert.equal(revokeResult.success, true);

    const revokedProofSnap = await db
      .collection("credentialProofs")
      .doc(proofId)
      .get();
    assert.equal(revokedProofSnap.get("status"), "revoked");

    await assert.rejects(
      () =>
        verifySelectiveDisclosureProof.run(
          { proofId, proofToken },
          authContext(companyUid),
        ),
      (error) => {
        assert.equal(error?.code, "failed-precondition");
        return true;
      },
    );
  },
);

test(
  "E2E ZKP: actor sin acceso de empresa/recruiter no puede verificar prueba",
  { timeout: 30_000 },
  async () => {
    const candidateUid = id("cand");
    const companyUid = id("comp");
    const outsiderUid = id("outsider");
    const applicationId = id("app");
    const jobOfferId = id("offer");
    const credentialId = id("cred");

    await Promise.all([
      db.collection("candidates").doc(candidateUid).set({
        uid: candidateUid,
        role: "candidate",
      }),
      db.collection("applications").doc(applicationId).set({
        candidate_uid: candidateUid,
        company_uid: companyUid,
        job_offer_id: jobOfferId,
        status: "pending",
      }),
      db
        .collection("candidates")
        .doc(candidateUid)
        .collection("verifiedCredentials")
        .doc(credentialId)
        .set({
          id: credentialId,
          type: "degree",
          title: "Ingeniería Informática",
          issuer: "UPM",
          verified: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
    ]);

    const createResult = await createSelectiveDisclosureProof.run(
      {
        credentialId,
        claimKey: "type",
        statement: "Prueba para permisos",
        applicationId,
      },
      authContext(candidateUid),
    );
    assertCamelCaseResponse(createResult, { path: "createSelectiveDisclosureProof.permissions" });

    await assert.rejects(
      () =>
        verifySelectiveDisclosureProof.run(
          {
            proofId: String(createResult.proofId),
            proofToken: String(createResult.proofToken),
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
  "E2E Firma cualificada: candidato firma oferta y empresa ve estado final aceptado",
  { timeout: 30_000 },
  async () => {
    const candidateUid = id("cand");
    const companyUid = id("comp");
    const jobOfferId = id("offer");
    const applicationId = id("app");

    await Promise.all([
      db.collection("candidates").doc(candidateUid).set({
        uid: candidateUid,
        role: "candidate",
        name: "Candidate Signature",
        email: `${candidateUid}@example.com`,
      }),
      db.collection("companies").doc(companyUid).set({
        uid: companyUid,
        role: "company",
        name: "Company Signature",
      }),
      db.collection("jobOffers").doc(jobOfferId).set({
        id: jobOfferId,
        title: "Senior Flutter Developer",
        company_uid: companyUid,
        salary_min: 55000,
        salary_max: 65000,
        salary_currency: "EUR",
        salary_period: "year",
        contract_type: "indefinido",
      }),
      db.collection("applications").doc(applicationId).set({
        candidate_uid: candidateUid,
        company_uid: companyUid,
        job_offer_id: jobOfferId,
        status: "offered",
      }),
    ]);

    const startResult = await startQualifiedOfferSignature.run(
      {
        applicationId,
        provider: "qualified_trust_service_eidas",
      },
      authContext(candidateUid),
    );
    assertCamelCaseResponse(startResult, { path: "startQualifiedOfferSignature" });

    assert.ok(startResult.requestId);
    assert.equal(startResult.applicationId, applicationId);
    assert.equal(startResult.legalFramework, "eIDAS_qualified_signature");
    assert.ok(startResult.documentHash);

    const requestId = String(startResult.requestId);
    const requestSnap = await db
      .collection("offerSignatureRequests")
      .doc(requestId)
      .get();
    assert.equal(requestSnap.exists, true);
    assert.equal(requestSnap.get("status"), "pending_candidate_signature");
    assert.equal(requestSnap.get("candidateUid"), candidateUid);
    assert.equal(requestSnap.get("companyUid"), companyUid);

    const appAfterStart = await db
      .collection("applications")
      .doc(applicationId)
      .get();
    assert.equal(appAfterStart.get("status"), "accepted_pending_signature");
    assert.equal(
      appAfterStart.get("contractSignature.status"),
      "pending_candidate_signature",
    );

    const companyPendingStatus = await getQualifiedOfferSignatureStatus.run(
      { applicationId },
      authContext(companyUid),
    );
    assertCamelCaseResponse(companyPendingStatus, {
      path: "getQualifiedOfferSignatureStatus.pending",
      deep: false,
    });
    assert.equal(companyPendingStatus.status, "accepted_pending_signature");
    assert.equal(
      companyPendingStatus.contractSignature.status,
      "pending_candidate_signature",
    );

    const confirmResult = await confirmQualifiedOfferSignature.run(
      {
        requestId,
        otpCode: "734925",
        certificateFingerprint: "CERT-FP-ABCD-2026",
        providerReference: "QTSP-REF-0001",
      },
      authContext(candidateUid),
    );
    assertCamelCaseResponse(confirmResult, { path: "confirmQualifiedOfferSignature" });

    assert.equal(confirmResult.success, true);
    assert.equal(confirmResult.applicationId, applicationId);
    assert.equal(confirmResult.status, "accepted");
    assert.equal(
      confirmResult.legalValidity,
      "qualified_electronic_signature_with_eidas_equivalence",
    );
    assert.ok(confirmResult.signatureId);

    const appAfterConfirm = await db
      .collection("applications")
      .doc(applicationId)
      .get();
    assert.equal(appAfterConfirm.get("status"), "accepted");
    assert.equal(appAfterConfirm.get("contractSignature.status"), "signed");
    assert.equal(
      appAfterConfirm.get("contractSignature.legalFramework"),
      "eIDAS_qualified_signature",
    );

    const signatureId = String(appAfterConfirm.get("contractSignature.signatureId"));
    const signatureSnap = await db
      .collection("qualifiedSignatures")
      .doc(signatureId)
      .get();
    assert.equal(signatureSnap.exists, true);
    assert.equal(signatureSnap.get("requestId"), requestId);
    assert.equal(signatureSnap.get("candidateUid"), candidateUid);
    assert.equal(signatureSnap.get("companyUid"), companyUid);

    const companyFinalStatus = await getQualifiedOfferSignatureStatus.run(
      { applicationId },
      authContext(companyUid),
    );
    assertCamelCaseResponse(companyFinalStatus, {
      path: "getQualifiedOfferSignatureStatus.final",
      deep: false,
    });
    assert.equal(companyFinalStatus.status, "accepted");
    assert.equal(companyFinalStatus.contractSignature.status, "signed");

    const startedAudit = await db
      .collection("auditLogs")
      .where("targetId", "==", requestId)
      .where("action", "==", "qualified_signature_started")
      .limit(1)
      .get();
    assert.equal(startedAudit.empty, false);
    assertAuditLogContract(startedAudit.docs[0].data());
  },
);

test(
  "E2E Firma cualificada: candidato no propietario no puede iniciar firma",
  { timeout: 30_000 },
  async () => {
    const ownerCandidateUid = id("cand_owner");
    const outsiderCandidateUid = id("cand_outsider");
    const companyUid = id("comp");
    const jobOfferId = id("offer");
    const applicationId = id("app");

    await db.collection("applications").doc(applicationId).set({
      candidate_uid: ownerCandidateUid,
      company_uid: companyUid,
      job_offer_id: jobOfferId,
      status: "offered",
    });

    await assert.rejects(
      () =>
        startQualifiedOfferSignature.run(
          {
            applicationId,
            provider: "qualified_trust_service_eidas",
          },
          authContext(outsiderCandidateUid),
        ),
      (error) => {
        assert.equal(error?.code, "permission-denied");
        return true;
      },
    );
  },
);

test(
  "E2E Firma cualificada: estado no firmable devuelve failed-precondition",
  { timeout: 30_000 },
  async () => {
    const candidateUid = id("cand");
    const companyUid = id("comp");
    const jobOfferId = id("offer");
    const applicationId = id("app");

    await db.collection("applications").doc(applicationId).set({
      candidate_uid: candidateUid,
      company_uid: companyUid,
      job_offer_id: jobOfferId,
      status: "pending",
    });

    await assert.rejects(
      () =>
        startQualifiedOfferSignature.run(
          {
            applicationId,
            provider: "qualified_trust_service_eidas",
          },
          authContext(candidateUid),
        ),
      (error) => {
        assert.equal(error?.code, "failed-precondition");
        return true;
      },
    );
  },
);
