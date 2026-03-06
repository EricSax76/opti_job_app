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
export { onRecruiterCreate } from "./triggers/firestore/onRecruiterCreate";
export { onRecruiterWrite } from "./triggers/firestore/onRecruiterWrite";
export {
  onCurriculumWriteRefreshEmbedding,
  onJobOfferWriteRefreshEmbedding,
} from "./triggers/firestore/vectorEmbeddings";
export {
  syncCandidateProfileToApplications,
  syncCompanyProfileToOffers,
  syncJobOfferTitleToApplications,
} from "./triggers/firestore/syncDenormalizedFields";
export { onApplicationStageChange } from "./triggers/firestore/onApplicationStageChange";
export { onEvaluationCreate } from "./triggers/firestore/evaluations/onEvaluationCreate";
export { onApprovalUpdate } from "./triggers/firestore/approvals/onApprovalUpdate";

// AI & Skills
export * from './scheduled/seedSkillsTaxonomy';
export * from './callable/ai/matchCandidateWithSkills';
export * from './callable/ai/matchCandidateVector';
export * from './callable/ai/getAiDecisionReview';
export * from './callable/ai/overrideAiDecision';

// Talent Pool
export * from './callable/talent/addToPool';
export * from './callable/talent/requestConsent';
export * from './scheduled/expireTalentPoolConsent';

// Compliance
export * from './callable/compliance/complianceCallables';
export * from './callable/compliance/salaryGapCallables';
export * from './callable/compliance/aiConsentCallables';
export * from './scheduled/complianceJobs';

// Analytics
export * from './scheduled/computeMonthlyAnalytics';
export * from './triggers/firestore/onApplicationStatusChange';
export * from './callable/analytics/getAnalyticsSummary';
export * from './callable/performance/webVitalsCallables';
export * from './scheduled/aggregateWebVitals';

// Callable Functions
export { submitApplication } from "./callable/applications/submitApplication";
export * from "./callable/auth/eudiWalletCallables";
export * from "./callable/auth/eudiSelectiveDisclosureCallables";
export * from "./callable/applications/qualifiedSignatureCallables";

// Interview Callables
export { startInterview } from "./callable/interviews/startInterview";
export { sendInterviewMessage } from "./callable/interviews/sendInterviewMessage";
export { proposeInterviewSlot } from "./callable/interviews/proposeInterviewSlot";
export { respondInterviewSlot } from "./callable/interviews/respondInterviewSlot";
export { markInterviewSeen } from "./callable/interviews/markInterviewSeen";
export { cancelInterview } from "./callable/interviews/cancelInterview";
export { completeInterview } from "./callable/interviews/completeInterview";

// ats
export { moveApplicationStage } from "./callable/ats/moveApplicationStage";
export { getApplicationsForReview } from "./callable/ats/getApplicationsForReview";
export { evaluateKnockoutQuestions } from "./callable/ats/evaluateKnockoutQuestions";
export { publishOfferMultiposting } from "./callable/ats/publishOfferMultiposting";
export { createJobOfferSecure } from "./callable/ats/createJobOfferSecure";

// recruiters
export { createInvitation } from "./callable/recruiters/createInvitation";
export { acceptInvitation } from "./callable/recruiters/acceptInvitation";
export { updateRecruiterRole } from "./callable/recruiters/updateRecruiterRole";
export { removeRecruiter } from "./callable/recruiters/removeRecruiter";
export { syncRecruiterClaims } from "./callable/recruiters/syncRecruiterClaims";

// evaluations
export { submitEvaluation } from "./callable/evaluations/submitEvaluation";
export { requestApproval } from "./callable/evaluations/requestApproval";

// Location catalog sync + public JSON endpoints
export {
  syncLocationCatalogScheduled,
  syncLocationCatalogManual,
  geoCatalogProvinces,
  geoCatalogMunicipalities,
} from "./scheduled/syncLocationCatalog";

// TODO: Add more functions as they are implemented
// export { generateCurriculumPDF } from "./callable/curriculum/generatePDF";
// export { matchCandidates } from "./callable/candidates/matchCandidates";
// export { sendEmail } from "./callable/notifications/sendEmail";
// export { dailyCleanup } from "./scheduled/dailyCleanup";
// export { expireOldOffers } from "./scheduled/expireOldOffers";
