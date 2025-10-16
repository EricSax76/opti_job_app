import { Module } from '@nestjs/common';

import { CoordinatorModule } from '../../agents/coordinator/coordinator.module.js';
import { OffersController } from './offers.controller.js';
import { OffersService } from './offers.service.js';

@Module({
  imports: [CoordinatorModule],
  controllers: [OffersController],
  providers: [OffersService],
  exports: [OffersService]
})
export class OffersModule {}
