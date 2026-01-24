/**
 * Firebase Cloud Functions for OptiJob
 *
 * Main entry point for all Cloud Functions.
 * Initialize Firebase Admin SDK and export all functions.
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Auth Triggers
export { onUserCreate } from "./triggers/auth/onUserCreate";
export { onUserDelete } from "./triggers/auth/onUserDelete";

// Firestore Triggers
export { onApplicationCreate } from "./triggers/firestore/onApplicationCreate";
export { onJobOfferCreate } from "./triggers/firestore/onJobOfferCreate";

// Callable Functions
export { submitApplication } from "./callable/applications/submitApplication";

// TODO: Add more functions as they are implemented
// export { generateCurriculumPDF } from "./callable/curriculum/generatePDF";
// export { matchCandidates } from "./callable/candidates/matchCandidates";
// export { sendEmail } from "./callable/notifications/sendEmail";
// export { dailyCleanup } from "./scheduled/dailyCleanup";
// export { expireOldOffers } from "./scheduled/expireOldOffers";
