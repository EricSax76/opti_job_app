import { Injectable, Logger } from '@nestjs/common';
import {
  type Application,
  type DomainEvent,
  type Offer,
  type MatchingComputeJob,
  type MatchingUpdateJob,
  type CalendarScheduleJob,
  type NotifyApplicationReceivedJob,
  type AntifraudCheckJob,
  type AnalyticsIngestJob
} from '@infojobs/shared-types';

import { QueuesService } from '../../common/queues/queues.service.js';

const MATCHING_COMPUTE_QUEUE = 'matching:compute';
const MATCHING_UPDATE_QUEUE = 'matching:update';
const CALENDAR_QUEUE = 'calendar:schedule';
const NOTIFY_QUEUE = 'notify:applicationReceived';
const ANTIFRAUD_QUEUE = 'antifraud:check';
const ANALYTICS_QUEUE = 'analytics:ingest';

@Injectable()
export class CoordinatorService {
  private readonly logger = new Logger(CoordinatorService.name);
  private readonly domainEvents: DomainEvent[] = [];

  constructor(private readonly queuesService: QueuesService) {}

  recordEvent(event: DomainEvent) {
    this.domainEvents.push(event);
    this.logger.debug(`Recorded event ${event.event}`);
  }

  getEvents() {
    return this.domainEvents.slice(-100);
  }

  async offerCreated(offer: Offer, top = 100) {
    this.recordEvent({
      event: 'OfferCreated',
      offerId: offer.id,
      companyId: offer.companyId,
      ts: new Date().toISOString()
    });
    await this.enqueueMatchingCompute({ offerId: offer.id, top });
  }

  async applicationCreated(application: Application) {
    this.recordEvent({
      event: 'ApplicationCreated',
      applicationId: application.id,
      offerId: application.offerId,
      candidateId: application.candidateId,
      ts: new Date().toISOString()
    });
    await this.enqueueAntifraudCheck({ applicationId: application.id });
    await this.enqueueMatchingUpdate({
      offerId: application.offerId,
      candidateId: application.candidateId
    });
    await this.enqueueNotify({
      candidateId: application.candidateId,
      offerId: application.offerId
    });
  }

  async matchingComputed(offerId: string, topCandidateIds: string[]) {
    this.recordEvent({
      event: 'MatchingComputed',
      offerId,
      topCandidateIds,
      ts: new Date().toISOString()
    });
  }

  async enqueueMatchingCompute(job: MatchingComputeJob) {
    const queue = this.queuesService.getQueue(MATCHING_COMPUTE_QUEUE);
    await queue.add(MATCHING_COMPUTE_QUEUE, job, {
      removeOnComplete: true,
      removeOnFail: true
    });
  }

  async enqueueMatchingUpdate(job: MatchingUpdateJob) {
    const queue = this.queuesService.getQueue(MATCHING_UPDATE_QUEUE);
    await queue.add(MATCHING_UPDATE_QUEUE, job, {
      removeOnComplete: true,
      removeOnFail: true
    });
  }

  async enqueueCalendar(job: CalendarScheduleJob) {
    const queue = this.queuesService.getQueue(CALENDAR_QUEUE);
    await queue.add(CALENDAR_QUEUE, job, {
      removeOnComplete: true,
      removeOnFail: true
    });
  }

  async enqueueNotify(job: NotifyApplicationReceivedJob) {
    const queue = this.queuesService.getQueue(NOTIFY_QUEUE);
    await queue.add(NOTIFY_QUEUE, job, {
      removeOnComplete: true,
      removeOnFail: true
    });
  }

  async enqueueAntifraudCheck(job: AntifraudCheckJob) {
    const queue = this.queuesService.getQueue(ANTIFRAUD_QUEUE);
    await queue.add(ANTIFRAUD_QUEUE, job, {
      removeOnComplete: true,
      removeOnFail: true
    });
  }

  async enqueueAnalytics<T extends Record<string, unknown>>(
    job: AnalyticsIngestJob<T>
  ) {
    const queue = this.queuesService.getQueue(ANALYTICS_QUEUE);
    await queue.add(ANALYTICS_QUEUE, job, {
      removeOnComplete: true,
      removeOnFail: true
    });
  }
}
