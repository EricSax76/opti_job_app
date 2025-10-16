import type { ConnectionOptions } from 'bullmq';
import type { AppConfig } from './env.js';

export function buildBullConnection(config: AppConfig): ConnectionOptions {
  const url = new URL(config.redisUrl);
  return {
    host: url.hostname,
    port: Number(url.port || 6379),
    password: url.password || undefined
  };
}
