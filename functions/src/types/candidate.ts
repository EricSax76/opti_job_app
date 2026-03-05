import * as FirebaseFirestore from 'firebase-admin/firestore';

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
