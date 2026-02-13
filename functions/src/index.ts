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
export { onInterviewUpdate } from "./triggers/firestore/onInterviewUpdate";

// Callable Functions
export { submitApplication } from "./callable/applications/submitApplication";

// Interview Callables
export { startInterview } from "./callable/interviews/startInterview";
export { sendInterviewMessage } from "./callable/interviews/sendInterviewMessage";
export { proposeInterviewSlot } from "./callable/interviews/proposeInterviewSlot";
export { respondInterviewSlot } from "./callable/interviews/respondInterviewSlot";
export { markInterviewSeen } from "./callable/interviews/markInterviewSeen";
export { cancelInterview } from "./callable/interviews/cancelInterview";
export { completeInterview } from "./callable/interviews/completeInterview";

// TODO: Add more functions as they are implemented
// export { generateCurriculumPDF } from "./callable/curriculum/generatePDF";
// export { matchCandidates } from "./callable/candidates/matchCandidates";
// export { sendEmail } from "./callable/notifications/sendEmail";
// export { dailyCleanup } from "./scheduled/dailyCleanup";
// export { expireOldOffers } from "./scheduled/expireOldOffers";
