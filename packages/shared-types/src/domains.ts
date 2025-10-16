export type Role = 'recruiter' | 'candidate' | 'admin';

export interface Company {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

export interface Recruiter {
  id: string;
  companyId: string;
  name: string;
  email: string;
  createdAt: string;
}

export interface Candidate {
  id: string;
  name: string;
  email: string;
  headline?: string;
  location?: string;
  skills: string[];
  cvUrl?: string;
  createdAt: string;
}

export interface Offer {
  id: string;
  companyId: string;
  title: string;
  description: string;
  skills: string[];
  seniority: 'junior' | 'mid' | 'senior';
  location: string;
  remote: boolean;
  createdAt: string;
  status: 'draft' | 'published' | 'archived';
}

export type ApplicationStatus =
  | 'pending'
  | 'screened'
  | 'interview'
  | 'offer'
  | 'rejected';

export interface Application {
  id: string;
  offerId: string;
  candidateId: string;
  coverLetter?: string;
  submittedAt: string;
  status: ApplicationStatus;
  riskScore?: number;
}

export interface Interview {
  id: string;
  offerId: string;
  candidateId: string;
  scheduledFor?: string;
  timezone?: string;
  roomUrl?: string;
  status: 'pending' | 'scheduled' | 'completed' | 'reschedule_requested';
}

export interface MatchingScore {
  offerId: string;
  candidateId: string;
  score: number;
  rank: number;
}
