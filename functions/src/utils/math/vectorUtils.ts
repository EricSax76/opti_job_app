import { createHash } from "crypto";

export const DEFAULT_EMBEDDING_DIMENSION = 256;

export function hashToIndex(token: string, dimension: number): number {
  const digest = createHash("sha256").update(token).digest();
  const seed = digest.readUInt32BE(0);
  return seed % dimension;
}

export function l2Normalize(values: number[]): number[] {
  const norm = Math.sqrt(values.reduce((sum, value) => sum + (value * value), 0));
  if (!Number.isFinite(norm) || norm <= 0) return values.map(() => 0);
  return values.map((value) => value / norm);
}

export function asFiniteDimension(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.max(8, Math.min(3072, Math.floor(value)));
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_EMBEDDING_DIMENSION;
  }
  return Math.max(8, Math.min(3072, Math.floor(parsed)));
}

export function toFiniteVector(values: unknown, dimension: number): number[] | null {
  if (!Array.isArray(values) || values.length === 0) return null;
  const vector: number[] = [];
  for (const item of values) {
    const num = Number(item);
    if (!Number.isFinite(num)) continue;
    vector.push(num);
  }
  if (vector.length === 0) return null;
  if (vector.length === dimension) return l2Normalize(vector);
  if (vector.length > dimension) return l2Normalize(vector.slice(0, dimension));

  const padded = [...vector];
  while (padded.length < dimension) padded.push(0);
  return l2Normalize(padded);
}

export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length === 0 || b.length === 0) return 0;
  const length = Math.min(a.length, b.length);
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let index = 0; index < length; index += 1) {
    const av = Number(a[index]);
    const bv = Number(b[index]);
    if (!Number.isFinite(av) || !Number.isFinite(bv)) continue;
    dot += av * bv;
    normA += av * av;
    normB += bv * bv;
  }
  if (normA <= 0 || normB <= 0) return 0;
  const cosine = dot / Math.sqrt(normA * normB);
  if (!Number.isFinite(cosine)) return 0;
  return Math.max(-1, Math.min(1, cosine));
}

export function cosineScore01(a: number[], b: number[]): number {
  const cosine = cosineSimilarity(a, b);
  return Math.max(0, Math.min(1, (cosine + 1) / 2));
}

import { compactWhitespace } from '../typeGuards';
export { compactWhitespace };
