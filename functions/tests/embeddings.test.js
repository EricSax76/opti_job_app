const assert = require("node:assert/strict");
const { test } = require("node:test");

const {
  buildCandidateEmbeddingText,
  buildJobOfferEmbeddingText,
  cosineScore01,
  cosineSimilarity,
  generateDeterministicEmbedding,
  hashText,
} = require("../lib/utils/embeddings.js");

test("generateDeterministicEmbedding returns normalized vector with stable dimension", () => {
  const vector = generateDeterministicEmbedding(
    "Senior Flutter engineer with Firebase and Dart",
    64,
  );

  assert.equal(vector.length, 64);
  const norm = Math.sqrt(vector.reduce((sum, value) => sum + (value * value), 0));
  assert.ok(norm > 0.99 && norm < 1.01);
});

test("deterministic embeddings are repeatable for same text", () => {
  const text = "Backend engineer TypeScript Node.js Firestore";
  const first = generateDeterministicEmbedding(text, 48);
  const second = generateDeterministicEmbedding(text, 48);

  assert.deepEqual(first, second);
  assert.equal(hashText(text), hashText(text));
});

test("cosine scoring ranks similar vectors above unrelated vectors", () => {
  const a = generateDeterministicEmbedding("flutter dart firebase", 64);
  const b = generateDeterministicEmbedding("dart flutter mobile firebase", 64);
  const c = generateDeterministicEmbedding("abogado laboralista derecho mercantil", 64);

  const simAB = cosineSimilarity(a, b);
  const simAC = cosineSimilarity(a, c);
  assert.ok(simAB > simAC);
  assert.ok(cosineScore01(a, b) > cosineScore01(a, c));
});

test("builders include core semantic features from candidate and offer", () => {
  const candidateText = buildCandidateEmbeddingText({
    candidate: {
      name: "Ana",
      title: "Flutter Developer",
      location: "Madrid",
      skills: ["Flutter", "Firebase"],
    },
    curriculum: {
      summary: "5 años construyendo apps móviles.",
      structuredSkills: [{ name: "Dart" }],
      experience: [
        {
          position: "Mobile Engineer",
          company: "Tech Co",
          description: "Mantenimiento y arquitectura.",
        },
      ],
    },
  });

  const offerText = buildJobOfferEmbeddingText({
    title: "Senior Flutter Engineer",
    description: "Trabajo con Firebase y Clean Architecture.",
    location: "Madrid",
    requiredSkills: ["Flutter", "Dart"],
    preferredSkills: ["Node.js"],
    experience_years: 3,
  });

  assert.ok(candidateText.includes("Flutter"));
  assert.ok(candidateText.includes("Firebase"));
  assert.ok(offerText.includes("Senior Flutter Engineer"));
  assert.ok(offerText.includes("Required skills"));
});

