import { Module } from '@nestjs/common';

import { QueuesModule } from '../../common/queues/queues.module.js';
import { CoordinatorService } from './coordinator.service.js';

@Module({
  imports: [QueuesModule],
  providers: [CoordinatorService],
  exports: [CoordinatorService]
})
export class CoordinatorModule {}
