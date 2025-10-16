import { Module } from '@nestjs/common';

import { CoordinatorModule } from '../../agents/coordinator/coordinator.module.js';
import { ApplicationsController } from './applications.controller.js';
import { ApplicationsService } from './applications.service.js';

@Module({
  imports: [CoordinatorModule],
  controllers: [ApplicationsController],
  providers: [ApplicationsService]
})
export class ApplicationsModule {}
