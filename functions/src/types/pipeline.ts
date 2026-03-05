import * as FirebaseFirestore from 'firebase-admin/firestore';

export interface PipelineStage {
  id: string;
  name: string;
  order: number;
  type: "new" | "screening" | "interview" | "offer" | "hired" | "rejected";
}

export interface Pipeline {
  id: string;
  companyId: string;
  name: string;
  stages: PipelineStage[];
  isTemplate: boolean;
  createdBy: string;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}
