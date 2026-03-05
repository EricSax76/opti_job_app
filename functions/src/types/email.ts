export type EmailTemplate =
  | "welcome"
  | "application_received"
  | "application_status_changed"
  | "new_matching_job"
  | "password_reset"
  | "interview_scheduled";

export interface EmailData {
  to: string;
  template: EmailTemplate;
  data: Record<string, any>; // eslint-disable-line @typescript-eslint/no-explicit-any
}
