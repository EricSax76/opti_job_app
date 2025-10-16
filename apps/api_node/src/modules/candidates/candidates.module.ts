import { Module } from '@nestjs/common';

import { AuthModule } from '../auth/auth.module.js';
import { CandidatesController } from './candidates.controller.js';
import { CandidatesService } from './candidates.service.js';

@Module({
  imports: [AuthModule],
  controllers: [CandidatesController],
  providers: [CandidatesService],
  exports: [CandidatesService]
})
export class CandidatesModule {}
