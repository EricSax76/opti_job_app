import { Module } from '@nestjs/common';

import { CoordinatorModule } from '../coordinator/coordinator.module.js';
import { AntifraudAgentService } from './antifraud-agent.service.js';

@Module({
  imports: [CoordinatorModule],
  providers: [AntifraudAgentService],
  exports: [AntifraudAgentService]
})
export class AntifraudAgentModule {}
