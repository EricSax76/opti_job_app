/**
 * Firestore helper utilities
 */

import * as admin from "firebase-admin";

/**
 * Get a document by ID or throw error if not found
 * @param {string} collection - Firestore collection name
 * @param {string} docId - Document ID
 * @param {string} errorMessage - Error message if not found
 * @return {Promise<T>} Document data
 */
export async function getDocumentOrThrow<T>(
  collection: string,
  docId: string,
  errorMessage = "Document not found"
): Promise<T> {
  const doc = await admin
    .firestore()
    .collection(collection)
    .doc(docId)
    .get();

  if (!doc.exists) {
    throw new Error(errorMessage);
  }

  return doc.data() as T;
}

/**
 * Query documents with WHERE clause
 * @param {string} collection - Firestore collection name
 * @param {string} field - Field to query
 * @param {FirebaseFirestore.WhereFilterOp} operator - Query operator
 * @param {unknown} value - Value to compare
 * @return {Promise<T[]>} Array of documents
 */
export async function queryDocuments<T>(
  collection: string,
  field: string,
  operator: FirebaseFirestore.WhereFilterOp,
  value: unknown
): Promise<T[]> {
  const snapshot = await admin
    .firestore()
    .collection(collection)
    .where(field, operator, value)
    .get();

  return snapshot.docs.map((doc) => doc.data() as T);
}

/**
 * Batch update documents
 * @param {Array} updates - Array of update operations
 * @return {Promise<void>}
 */
export async function batchUpdate(
  updates: Array<{
    collection: string;
    docId: string;
    data: Record<string, unknown>;
  }>
): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  updates.forEach(({ collection, docId, data }) => {
    const ref = db.collection(collection).doc(docId);
    batch.update(ref, data);
  });

  await batch.commit();
}

/**
 * Check if document exists
 * @param {string} collection - Firestore collection name
 * @param {string} docId - Document ID
 * @return {Promise<boolean>} True if document exists
 */
export async function documentExists(
  collection: string,
  docId: string
): Promise<boolean> {
  const doc = await admin
    .firestore()
    .collection(collection)
    .doc(docId)
    .get();

  return doc.exists;
}

/**
 * Get server timestamp
 * @return {FirebaseFirestore.FieldValue} Server timestamp
 */
export function serverTimestamp(): FirebaseFirestore.FieldValue {
  return admin.firestore.FieldValue.serverTimestamp();
}

/**
 * Chunk array for batch operations (Firestore has limit of 10 for whereIn)
 * @param {T[]} array - Array to chunk
 * @param {number} size - Chunk size
 * @return {T[][]} Array of chunks
 */
export function chunkArray<T>(array: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}
