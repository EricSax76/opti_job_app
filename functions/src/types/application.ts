import * as FirebaseFirestore from 'firebase-admin/firestore';

export interface Application {
  id: string;
  job_offer_id: string;
  candidate_uid: string;
  candidate_name: string;
  candidate_email: string;
  candidate_avatar_url?: string;
  company_uid: string;
  curriculum_id: string;
  cover_letter?: string;
  additional_documents?: string[];
  status:
    | "pending"
    | "reviewing"
    | "interviewing"
    | "offered"
    | "hired"
    | "rejected"
    | "withdrawn";
  pipelineStageId?: string;
  pipelineStageName?: string;
  pipelineHistory?: Array<{
    stageId: string;
    stageName: string;
    movedBy: string; // User ID who moved it
    movedAt: string; // ISO String mapping string in TypeScript interfaces handling dates
  }>;
  knockoutResponses?: Record<string, string | boolean>;
  knockoutPassed?: boolean;
  requiresHumanReview?: boolean;
  aiConsentRequired?: boolean;
  aiConsentScopeRequired?: string;
  aiConsentStatus?: "missing_or_invalid" | "granted";
  aiConsentBlockedAt?: FirebaseFirestore.Timestamp | null;
  knockoutEvaluationStatus?: "completed" | "blocked_consent" | "failed";
  knockoutEvaluationNeedsAttention?: boolean;
  knockoutEvaluationLastErrorCode?: string | null;
  knockoutEvaluationLastErrorMessage?: string | null;
  knockoutEvaluationLastAttemptAt?: FirebaseFirestore.Timestamp;
  knockoutEvaluationAttempts?: number;
  assignedTo?: string; // UID del reclutador asignado
  match_score?: number;
  aiMatchResult?: Record<string, unknown>;
  // Blind review — LGPD progressive reveal
  identityRevealed?: boolean;
  identityRevealedAt?: FirebaseFirestore.Timestamp;
  identityRevealedBy?: string;
  submitted_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
}
