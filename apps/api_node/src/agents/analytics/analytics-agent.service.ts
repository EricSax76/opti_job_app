import { Injectable, Logger } from '@nestjs/common';
import type { AnalyticsIngestJob } from '@infojobs/shared-types';

@Injectable()
export class AnalyticsAgentService {
  private readonly logger = new Logger(AnalyticsAgentService.name);

  async process(job: AnalyticsIngestJob) {
    this.logger.log(`Analytics ingest: ${job.event}`);
  }
}
