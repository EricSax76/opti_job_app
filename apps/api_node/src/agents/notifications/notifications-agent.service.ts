import { Injectable, Logger } from '@nestjs/common';
import type { NotifyApplicationReceivedJob } from '@infojobs/shared-types';

@Injectable()
export class NotificationsAgentService {
  private readonly logger = new Logger(NotificationsAgentService.name);

  async process(job: NotifyApplicationReceivedJob) {
    this.logger.log(
      `Notify candidate ${job.candidateId} about application to offer ${job.offerId}`
    );
  }
}
