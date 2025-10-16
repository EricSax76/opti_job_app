import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';
import { RecruitersController } from './recruiters.controller.js';
import { RecruitersService } from './recruiters.service.js';

@Module({
  imports: [AuthModule],
  controllers: [RecruitersController],
  providers: [RecruitersService],
  exports: [RecruitersService]
})
export class RecruitersModule {}
