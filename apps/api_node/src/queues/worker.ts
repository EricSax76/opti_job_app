import 'reflect-metadata';
import { Worker } from 'bullmq';
import { NestFactory } from '@nestjs/core';
import { Logger } from '@nestjs/common';
import { buildBullConnection, type AppConfig } from '@infojobs/shared-config';

import { AppModule } from '../app.module.js';
import { APP_CONFIG } from '../common/config/app-config.provider.js';
import { MatchingAgentService } from '../agents/matching/matching-agent.service.js';
import { CalendarsAgentService } from '../agents/calendars/calendars-agent.service.js';
import { NotificationsAgentService } from '../agents/notifications/notifications-agent.service.js';
import { AntifraudAgentService } from '../agents/antifraud/antifraud-agent.service.js';
import { AnalyticsAgentService } from '../agents/analytics/analytics-agent.service.js';

async function bootstrapWorkers() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['log', 'error', 'warn']
  });
  const logger = new Logger('QueuesBootstrap');
  const config = app.get<AppConfig>(APP_CONFIG);
  const connection = buildBullConnection(config);

  const matchingAgent = app.get(MatchingAgentService);
  const calendarAgent = app.get(CalendarsAgentService);
  const notificationsAgent = app.get(NotificationsAgentService);
  const antifraudAgent = app.get(AntifraudAgentService);
  const analyticsAgent = app.get(AnalyticsAgentService);

  new Worker(
    'matching:compute',
    async (job) => matchingAgent.processCompute(job.data),
    { connection }
  );
  new Worker(
    'matching:update',
    async (job) => matchingAgent.processUpdate(job.data),
    { connection }
  );
  new Worker('calendar:schedule', async (job) => calendarAgent.process(job.data), {
    connection
  });
  new Worker(
    'notify:applicationReceived',
    async (job) => notificationsAgent.process(job.data),
    { connection }
  );
  new Worker('antifraud:check', async (job) => antifraudAgent.process(job.data), {
    connection
  });
  new Worker('analytics:ingest', async (job) => analyticsAgent.process(job.data), {
    connection
  });

  logger.log('Workers started');
}

bootstrapWorkers().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Failed to start workers', error);
  process.exit(1);
});
