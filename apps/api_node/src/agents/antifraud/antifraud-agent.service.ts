import { Injectable, Logger } from '@nestjs/common';
import type { AntifraudCheckJob, FraudFlaggedEvent } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { CoordinatorService } from '../coordinator/coordinator.service.js';

const SUSPICIOUS_KEYWORDS = ['bitcoin', 'telegram', 'crypto'];

@Injectable()
export class AntifraudAgentService {
  private readonly logger = new Logger(AntifraudAgentService.name);

  constructor(
    private readonly db: InMemoryDatabase,
    private readonly coordinatorService: CoordinatorService
  ) {}

  async process(job: AntifraudCheckJob) {
    const application = this.db.getApplication(job.applicationId);
    if (!application) {
      this.logger.warn(`Application ${job.applicationId} not found`);
      return;
    }
    let riskScore = 0;
    const cover = application.coverLetter?.toLowerCase() ?? '';
    if (SUSPICIOUS_KEYWORDS.some((keyword) => cover.includes(keyword))) {
      riskScore += 60;
    }
    if ((job.signals ?? []).includes('dup_cv')) {
      riskScore += 30;
    }
    if ((job.signals ?? []).includes('keyword_spam')) {
      riskScore += 20;
    }
    const updated = {
      ...application,
      riskScore
    };
    this.db.upsertApplication(updated);

    if (riskScore > 70) {
      await this.coordinatorService.enqueueAnalytics({
        event: 'fraud.flagged',
        payload: {
          applicationId: application.id,
          riskScore
        }
      });
      const event: FraudFlaggedEvent = {
        event: 'FraudFlagged',
        applicationId: application.id,
        riskScore,
        statusAfterReview: updated.status,
        ts: new Date().toISOString()
      };
      this.coordinatorService.recordEvent(event);
    }
  }
}
