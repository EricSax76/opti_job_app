const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');

const { verifyEudiPresentation } = require('../lib/utils/eudiCryptoVerifier');

const ISSUER_DID = 'did:example:issuer:opti';
const EXPECTED_AUDIENCE = 'opti-job-app:eudi-import';

function base64UrlEncode(inputBuffer) {
  return Buffer.from(inputBuffer)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function signJwt({ payload, privateKey }) {
  const header = { alg: 'RS256', typ: 'JWT', kid: 'did:example:issuer:opti#key-1' };
  const encodedHeader = base64UrlEncode(Buffer.from(JSON.stringify(header), 'utf8'));
  const encodedPayload = base64UrlEncode(Buffer.from(JSON.stringify(payload), 'utf8'));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signature = crypto.sign('RSA-SHA256', Buffer.from(signingInput, 'utf8'), privateKey);
  const encodedSignature = base64UrlEncode(signature);
  return `${signingInput}.${encodedSignature}`;
}

function createTrustedIssuers(publicKeyPem) {
  return {
    [ISSUER_DID]: {
      publicPem: publicKeyPem,
      allowedAudiences: [EXPECTED_AUDIENCE],
      allowedAlgorithms: ['RS256'],
      active: true,
    },
  };
}

test('verifyEudiPresentation validates signature, issuer, exp and audience', () => {
  const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
  });
  const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' });

  const payload = {
    iss: ISSUER_DID,
    sub: 'did:wallet:candidate:123',
    aud: [EXPECTED_AUDIENCE],
    exp: Math.floor(Date.now() / 1000) + 60 * 30,
    iat: Math.floor(Date.now() / 1000) - 60,
    assuranceLevel: 'high',
    vc: {
      id: 'urn:uuid:cred-123',
      type: ['VerifiableCredential', 'EducationCredential'],
      issuer: ISSUER_DID,
      issuanceDate: '2025-06-01T10:30:00.000Z',
      expirationDate: '2030-06-01T10:30:00.000Z',
      credentialSubject: {
        id: 'did:wallet:candidate:123',
        email: 'ana@example.com',
        fullName: 'Ana Dev',
        countryCode: 'es',
        title: 'Master en Ingeniería',
      },
    },
  };

  const token = signJwt({ payload, privateKey });
  const result = verifyEudiPresentation({
    verifiablePresentation: token,
    expectedAudience: EXPECTED_AUDIENCE,
    proofSchemaVersion: '2026.1',
    trustedIssuers: createTrustedIssuers(publicKeyPem),
  });

  assert.equal(result.walletSubject, 'did:wallet:candidate:123');
  assert.equal(result.email, 'ana@example.com');
  assert.equal(result.fullName, 'Ana Dev');
  assert.equal(result.countryCode, 'ES');
  assert.equal(result.issuerDid, ISSUER_DID);
  assert.equal(result.credentialType, 'EducationCredential');
  assert.equal(result.credentialTitle, 'Master en Ingeniería');
  assert.equal(result.proofSchemaVersion, '2026.1');
  assert.ok(result.verifiablePresentationHash.length > 10);
});

test('verifyEudiPresentation rejects wrong audience', () => {
  const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
  });
  const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' });

  const payload = {
    iss: ISSUER_DID,
    sub: 'did:wallet:candidate:123',
    aud: ['other-audience'],
    exp: Math.floor(Date.now() / 1000) + 60 * 15,
    vc: {
      type: ['VerifiableCredential', 'EducationCredential'],
      issuer: ISSUER_DID,
      credentialSubject: {
        id: 'did:wallet:candidate:123',
      },
    },
  };

  const token = signJwt({ payload, privateKey });

  assert.throws(() => {
    verifyEudiPresentation({
      verifiablePresentation: token,
      expectedAudience: EXPECTED_AUDIENCE,
      proofSchemaVersion: '2026.1',
      trustedIssuers: createTrustedIssuers(publicKeyPem),
    });
  }, /audiencia/i);
});

test('verifyEudiPresentation rejects expired presentation', () => {
  const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
  });
  const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' });

  const payload = {
    iss: ISSUER_DID,
    sub: 'did:wallet:candidate:123',
    aud: [EXPECTED_AUDIENCE],
    exp: Math.floor(Date.now() / 1000) - 10,
    vc: {
      type: ['VerifiableCredential', 'EducationCredential'],
      issuer: ISSUER_DID,
      credentialSubject: {
        id: 'did:wallet:candidate:123',
      },
    },
  };

  const token = signJwt({ payload, privateKey });

  assert.throws(() => {
    verifyEudiPresentation({
      verifiablePresentation: token,
      expectedAudience: EXPECTED_AUDIENCE,
      proofSchemaVersion: '2026.1',
      trustedIssuers: createTrustedIssuers(publicKeyPem),
    });
  }, /expirada/i);
});

test('verifyEudiPresentation rejects invalid signature', () => {
  const { publicKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
  });
  const { privateKey: attackerPrivateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
  });
  const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' });

  const payload = {
    iss: ISSUER_DID,
    sub: 'did:wallet:candidate:123',
    aud: [EXPECTED_AUDIENCE],
    exp: Math.floor(Date.now() / 1000) + 600,
    vc: {
      type: ['VerifiableCredential', 'EducationCredential'],
      issuer: ISSUER_DID,
      credentialSubject: {
        id: 'did:wallet:candidate:123',
      },
    },
  };

  const token = signJwt({ payload, privateKey: attackerPrivateKey });

  assert.throws(() => {
    verifyEudiPresentation({
      verifiablePresentation: token,
      expectedAudience: EXPECTED_AUDIENCE,
      proofSchemaVersion: '2026.1',
      trustedIssuers: createTrustedIssuers(publicKeyPem),
    });
  }, /firma inválida/i);
});
