import { Module } from '@nestjs/common';

import { CalendarsAgentService } from './calendars-agent.service.js';

@Module({
  providers: [CalendarsAgentService],
  exports: [CalendarsAgentService]
})
export class CalendarsAgentModule {}
