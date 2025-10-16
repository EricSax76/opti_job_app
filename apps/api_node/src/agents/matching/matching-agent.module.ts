import { Module } from '@nestjs/common';

import { CoordinatorModule } from '../coordinator/coordinator.module.js';
import { MatchingAgentService } from './matching-agent.service.js';

@Module({
  imports: [CoordinatorModule],
  providers: [MatchingAgentService],
  exports: [MatchingAgentService]
})
export class MatchingAgentModule {}
