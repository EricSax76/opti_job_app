import * as FirebaseFirestore from 'firebase-admin/firestore';
import { Application } from './application';

export interface SubmitApplicationRequest {
  jobOfferId: string;
  coverLetter?: string;
  curriculumId?: string;
  additionalDocuments?: string[];
  sourceChannel?: string;
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
