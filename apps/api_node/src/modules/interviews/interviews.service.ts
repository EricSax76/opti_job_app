import { Injectable, NotFoundException } from '@nestjs/common';
import type { Interview } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { CoordinatorService } from '../../agents/coordinator/coordinator.service.js';
import { generateId } from '../../common/utils/id.util.js';
import { CreateInterviewDto } from './dto/create-interview.dto.js';
import { RescheduleInterviewDto } from './dto/reschedule-interview.dto.js';

@Injectable()
export class InterviewsService {
  constructor(
    private readonly db: InMemoryDatabase,
    private readonly coordinatorService: CoordinatorService
  ) {}

  async create(dto: CreateInterviewDto): Promise<Interview> {
    const offer = this.db.getOffer(dto.offerId);
    if (!offer) {
      throw new NotFoundException('Offer not found');
    }
    const candidate = this.db.getCandidate(dto.candidateId);
    if (!candidate) {
      throw new NotFoundException('Candidate not found');
    }
    const interview: Interview = {
      id: generateId('int'),
      offerId: offer.id,
      candidateId: candidate.id,
      status: 'pending',
      timezone: dto.window.tz
    };
    this.db.upsertInterview(interview);
    await this.coordinatorService.enqueueCalendar({
      interviewId: interview.id,
      window: dto.window
    });
    return interview;
  }

  findById(id: string): Interview {
    const interview = this.db.getInterview(id);
    if (!interview) {
      throw new NotFoundException('Interview not found');
    }
    return interview;
  }

  async reschedule(id: string, dto: RescheduleInterviewDto) {
    const interview = this.findById(id);
    const updated: Interview = {
      ...interview,
      status: 'reschedule_requested',
      timezone: dto.window.tz
    };
    this.db.upsertInterview(updated);
    await this.coordinatorService.enqueueCalendar({
      interviewId: id,
      window: dto.window
    });
    return updated;
  }
}
