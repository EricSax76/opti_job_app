/**
 * Shared TypeScript types for OptiJob Cloud Functions
 */

export interface UserProfile {
  uid: string;
  email: string;
  role: "candidate" | "company";
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface Company {
  id: number;
  uid: string;
  name: string;
  email: string;
  avatar_url?: string;
  description?: string;
  website?: string;
  location?: string;
  industry?: string;
  created_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
}

export interface Candidate {
  id: number;
  uid: string;
  name: string;
  email: string;
  avatar_url?: string;
  phone?: string;
  location?: string;
  title?: string;
  bio?: string;
  created_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
}

export interface JobOffer {
  id: string;
  company_uid: string;
  company_name: string;
  company_avatar_url?: string;
  title: string;
  description: string;
  location: string;
  job_type: "full_time" | "part_time" | "contract" | "internship";
  salary_min?: number;
  salary_max?: number;
  education?: string;
  experience_years?: number;
  skills: string[];
  status: "active" | "closed" | "expired" | "draft";
  applications_count: number;
  expires_at?: FirebaseFirestore.Timestamp;
  created_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
}

export interface Application {
  id: string;
  job_offer_id: string;
  candidate_uid: string;
  candidate_name: string;
  candidate_email: string;
  curriculum_id: string;
  cover_letter?: string;
  status: "submitted" | "reviewing" | "interview" | "rejected" | "accepted" | "withdrawn";
  match_score?: number;
  submitted_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
}

export interface Curriculum {
  id: string;
  uid: string;
  personal_info: PersonalInfo;
  experience: Experience[];
  education: Education[];
  skills: string[];
  languages: Language[];
  certifications?: Certification[];
  summary?: string;
  created_at: FirebaseFirestore.Timestamp;
  updated_at: FirebaseFirestore.Timestamp;
}

export interface PersonalInfo {
  full_name: string;
  email: string;
  phone?: string;
  location?: string;
  linkedin?: string;
  portfolio?: string;
}

export interface Experience {
  id: string;
  company: string;
  position: string;
  location?: string;
  start_date: string;
  end_date?: string;
  current: boolean;
  description?: string;
}

export interface Education {
  id: string;
  institution: string;
  degree: string;
  field: string;
  start_date: string;
  end_date?: string;
  current: boolean;
  description?: string;
}

export interface Language {
  name: string;
  proficiency: "basic" | "intermediate" | "advanced" | "native";
}

export interface Certification {
  id: string;
  name: string;
  issuer: string;
  date: string;
  credential_id?: string;
  credential_url?: string;
}

// Email templates
export type EmailTemplate =
  | "welcome"
  | "application_received"
  | "application_status_changed"
  | "new_matching_job"
  | "password_reset"
  | "interview_scheduled";

export interface EmailData {
  to: string;
  template: EmailTemplate;
  data: Record<string, any>; // eslint-disable-line @typescript-eslint/no-explicit-any
}

// Callable Functions request/response types
export interface SubmitApplicationRequest {
  jobOfferId: string;
  coverLetter?: string;
  curriculumId: string;
  additionalDocuments?: string[];
}

export interface SubmitApplicationResponse {
  applicationId: string;
  status: Application["status"];
  matchScore?: number;
  submittedAt: FirebaseFirestore.Timestamp;
}

export interface GeneratePDFRequest {
  curriculumId: string;
  template?: "modern" | "classic" | "creative";
  language?: "es" | "en";
}

export interface GeneratePDFResponse {
  pdfUrl: string;
  expiresAt: FirebaseFirestore.Timestamp;
}

export interface MatchCandidatesRequest {
  jobOfferId: string;
  limit?: number;
}

export interface CandidateMatch {
  candidateId: string;
  matchScore: number;
  reasons: string[];
  missingSkills: string[];
}

export interface MatchCandidatesResponse {
  matches: CandidateMatch[];
  totalCandidates: number;
}

export interface Interview {
  id: string; // Same as applicationId
  applicationId: string;
  jobOfferId: string;
  companyUid: string;
  candidateUid: string;
  participants: string[]; // [companyUid, candidateUid] for security rules
  status: "scheduling" | "scheduled" | "completed" | "cancelled";
  scheduledAt?: FirebaseFirestore.Timestamp;
  timeZone?: string; // e.g. 'Europe/Madrid'
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  unreadCounts?: Record<string, number>; // Map of uid -> count
  lastMessage?: {
    content: string;
    senderUid: string;
    createdAt: FirebaseFirestore.Timestamp;
  };
}

export interface Message {
  id: string;
  senderUid: string;
  content: string;
  type: "text" | "proposal" | "acceptance" | "rejection" | "system";
  metadata?: {
    proposalId?: string;
    proposedAt?: FirebaseFirestore.Timestamp;
    timeZone?: string;
    // Add other metadata as needed
  };
  createdAt: FirebaseFirestore.Timestamp;
  readByData?: Record<string, FirebaseFirestore.Timestamp>; // Map of uid -> readAt
}
