import { Module } from '@nestjs/common';

import { CoordinatorModule } from '../../agents/coordinator/coordinator.module.js';
import { InterviewsController } from './interviews.controller.js';
import { InterviewsService } from './interviews.service.js';

@Module({
  imports: [CoordinatorModule],
  controllers: [InterviewsController],
  providers: [InterviewsService]
})
export class InterviewsModule {}
