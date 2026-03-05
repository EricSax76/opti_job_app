import * as FirebaseFirestore from 'firebase-admin/firestore';

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
