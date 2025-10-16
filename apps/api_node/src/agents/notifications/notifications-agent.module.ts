import { Module } from '@nestjs/common';

import { NotificationsAgentService } from './notifications-agent.service.js';

@Module({
  providers: [NotificationsAgentService],
  exports: [NotificationsAgentService]
})
export class NotificationsAgentModule {}
