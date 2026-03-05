import * as FirebaseFirestore from 'firebase-admin/firestore';

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
