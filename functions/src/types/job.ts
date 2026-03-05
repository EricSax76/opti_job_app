import * as FirebaseFirestore from 'firebase-admin/firestore';
import { PipelineStage } from './pipeline';

export interface KnockoutQuestion {
  id: string;
  question: string;
  type: "boolean" | "multiple_choice" | "text";
  options?: string[]; // Para multiple_choice
  requiredAnswer?: string | boolean; // Si no coincide, auto-filtro
}

export interface JobOffer {
  id: string;
  company_uid: string;
  company_name: string;
  company_avatar_url?: string;
  pipelineId?: string;
  pipelineStages?: PipelineStage[];
  knockoutQuestions?: KnockoutQuestion[];
  title: string;
  description: string;
  location: string;
  job_type: string;
  salary_min: number | string;
  salary_max: number | string;
  salary_currency: string;
  salary_period: string;
  language_check_result?: {
    score: number;
    issues: string[];
    checkedAt: string;
  };
  education?: string;
  job_category?: string;
  work_schedule?: string;
  contract_type?: string;
  experience_years?: number;
  skills: string[];
  status:
    | "active"
    | "closed"
    | "expired"
    | "draft"
    | "blocked_pending_salary_justification";
  applications_count: number;
  expires_at?: FirebaseFirestore.Timestamp;
  created_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
}
