export interface MatchingComputeJob {
  offerId: string;
  top?: number;
  filters?: {
    remote?: boolean;
    languages?: string[];
    locations?: string[];
  };
}

export interface MatchingUpdateJob {
  offerId: string;
  candidateId: string;
}

export interface CalendarScheduleJob {
  interviewId: string;
  window: {
    days: number;
    tz: string;
  };
}

export interface NotifyApplicationReceivedJob {
  candidateId: string;
  offerId: string;
}

export interface AntifraudCheckJob {
  applicationId: string;
  signals?: string[];
}

export interface AnalyticsIngestJob<T = Record<string, unknown>> {
  event: string;
  payload: T;
}

export type QueueJobPayload =
  | MatchingComputeJob
  | MatchingUpdateJob
  | CalendarScheduleJob
  | NotifyApplicationReceivedJob
  | AntifraudCheckJob
  | AnalyticsIngestJob;
