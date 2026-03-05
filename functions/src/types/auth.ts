import * as FirebaseFirestore from 'firebase-admin/firestore';

export interface UserProfile {
  uid: string;
  email: string;
  role: "candidate" | "company";
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface Recruiter {
  uid: string;
  companyId: string;
  email: string;
  name: string;
  role:
    | "admin"
    | "recruiter"
    | "hiring_manager"
    | "external_evaluator"
    | "viewer"
    | "legal"
    | "auditor";
  status: "active" | "invited" | "disabled";
  invitedBy?: string;
  invitedAt?: FirebaseFirestore.Timestamp;
  acceptedAt?: FirebaseFirestore.Timestamp;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface Invitation {
  code: string;
  companyId: string;
  role:
    | "admin"
    | "recruiter"
    | "hiring_manager"
    | "external_evaluator"
    | "viewer"
    | "legal"
    | "auditor";
  email?: string;
  createdBy: string;
  usedBy?: string;
  status: "pending" | "accepted" | "expired";
  createdAt: FirebaseFirestore.Timestamp;
  expiresAt: FirebaseFirestore.Timestamp;
}
