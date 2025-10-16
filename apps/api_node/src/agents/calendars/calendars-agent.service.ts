import { Injectable, Logger } from '@nestjs/common';
import type { CalendarScheduleJob } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { generateId } from '../../common/utils/id.util.js';

@Injectable()
export class CalendarsAgentService {
  private readonly logger = new Logger(CalendarsAgentService.name);

  constructor(private readonly db: InMemoryDatabase) {}

  async process(job: CalendarScheduleJob) {
    const interview = this.db.getInterview(job.interviewId);
    if (!interview) {
      this.logger.warn(`Interview ${job.interviewId} not found`);
      return;
    }
    const now = new Date();
    const proposal = new Date(
      now.getTime() + Math.floor(Math.random() * job.window.days) * 24 * 60 * 60 * 1000
    );
    const updated = {
      ...interview,
      status: 'scheduled' as const,
      scheduledFor: proposal.toISOString(),
      roomUrl: `https://meet.example.com/${generateId('room')}`
    };
    this.db.upsertInterview(updated);
  }
}
