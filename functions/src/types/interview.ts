import * as FirebaseFirestore from 'firebase-admin/firestore';

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
