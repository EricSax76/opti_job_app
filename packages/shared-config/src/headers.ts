import { randomUUID } from 'node:crypto';

export const IDEMPOTENCY_HEADER = 'Idempotency-Key';
export const TRACE_ID_HEADER = 'X-Trace-Id';
export const AUTH_HEADER = 'Authorization';

export function buildTraceId(): string {
  return `trace_${randomUUID()}`;
}

export function ensureBearer(token?: string): string | undefined {
  if (!token) {
    return undefined;
  }
  return token.startsWith('Bearer ') ? token : `Bearer ${token}`;
}
