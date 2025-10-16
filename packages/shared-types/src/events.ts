import type { ApplicationStatus } from './domains.js';

export interface OfferCreatedEvent {
  event: 'OfferCreated';
  offerId: string;
  companyId: string;
  ts: string;
}

export interface ApplicationCreatedEvent {
  event: 'ApplicationCreated';
  applicationId: string;
  offerId: string;
  candidateId: string;
  ts: string;
}

export interface MatchingComputedEvent {
  event: 'MatchingComputed';
  offerId: string;
  topCandidateIds: string[];
  ts: string;
}

export interface InterviewScheduledEvent {
  event: 'InterviewScheduled';
  interviewId: string;
  offerId: string;
  candidateId: string;
  ts: string;
}

export interface FraudFlaggedEvent {
  event: 'FraudFlagged';
  applicationId: string;
  riskScore: number;
  statusAfterReview: ApplicationStatus;
  ts: string;
}

export type DomainEvent =
  | OfferCreatedEvent
  | ApplicationCreatedEvent
  | MatchingComputedEvent
  | InterviewScheduledEvent
  | FraudFlaggedEvent;
