# Critical Callable Test Matrix

This matrix defines the minimum automated E2E coverage for critical callable modules:
- `auth`
- `applications`
- `ats`
- `interviews`
- `compliance`

## Execution Command
- `npm run test:e2e:critical`

## Coverage Matrix
| Module | Callable(s) | Happy path | Permission check | Key error check | Evidence file(s) |
|---|---|---|---|---|---|
| auth | `createSelectiveDisclosureProof`, `verifySelectiveDisclosureProof`, `revokeSelectiveDisclosureProof` | Candidate creates proof, company verifies, candidate revokes | Non company/recruiter actor cannot verify | Verifying revoked proof returns `failed-precondition` | `e2e/p2_candidate_company_flows.test.js` |
| applications | `startQualifiedOfferSignature`, `confirmQualifiedOfferSignature`, `getQualifiedOfferSignatureStatus` | Candidate signs and company sees final `accepted` status | Non-owner candidate cannot start signature | Non-signable status returns `failed-precondition` | `e2e/p2_candidate_company_flows.test.js` |
| ats | `evaluateKnockoutQuestions` | Valid consent + valid answers complete evaluation | Non-owner candidate gets `permission-denied` | Missing offer returns `not-found`; missing consent flags `blocked_consent` | `e2e/p3_ats_knockout_hardening.test.js` |
| interviews | `cancelInterview`, `completeInterview`, `startMeeting` | Participant/company can cancel/complete/start meeting | Non participant cannot start meeting; candidate cannot complete | Closed interview start returns `failed-precondition` | `e2e/p3_interviews_actions_callables.test.js`, `e2e/p3_interviews_start_meeting_callable.test.js` |
| compliance | `processDataRequest`, `exportCandidateData`, `upsertSalaryBenchmark` | Processing request and export register operational metrics; benchmark upsert by allowed roles | Recruiter `viewer` cannot upsert benchmark | SLA breach path flagged; operation metrics and events persisted | `e2e/p3_compliance_observability.test.js`, `e2e/p3_compliance_salary_benchmark.test.js` |

## Acceptance Rule
BL-015 is considered complete when:
1. `npm run test:e2e:critical` passes in Firebase emulators.
2. Every critical module has at least one automated case for:
   - happy path
   - permission control
   - key error/edge condition
