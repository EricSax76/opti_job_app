import { Module } from '@nestjs/common';

import { AnalyticsAgentService } from './analytics-agent.service.js';

@Module({
  providers: [AnalyticsAgentService],
  exports: [AnalyticsAgentService]
})
export class AnalyticsAgentModule {}
