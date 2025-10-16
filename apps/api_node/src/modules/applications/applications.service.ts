import { Injectable, NotFoundException } from '@nestjs/common';
import type { Application } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { CoordinatorService } from '../../agents/coordinator/coordinator.service.js';
import { generateId } from '../../common/utils/id.util.js';
import { CreateApplicationDto } from './dto/create-application.dto.js';
import { UpdateApplicationStatusDto } from './dto/update-application-status.dto.js';

@Injectable()
export class ApplicationsService {
  constructor(
    private readonly db: InMemoryDatabase,
    private readonly coordinatorService: CoordinatorService
  ) {}

  async create(dto: CreateApplicationDto): Promise<Application> {
    const offer = this.db.getOffer(dto.offerId);
    if (!offer) {
      throw new NotFoundException('Offer not found');
    }
    const candidate = this.db.getCandidate(dto.candidateId);
    if (!candidate) {
      throw new NotFoundException('Candidate not found');
    }
    const application: Application = {
      id: generateId('app'),
      offerId: offer.id,
      candidateId: candidate.id,
      coverLetter: dto.coverLetter,
      submittedAt: new Date().toISOString(),
      status: 'pending'
    };
    this.db.upsertApplication(application);
    await this.coordinatorService.applicationCreated(application);
    await this.coordinatorService.enqueueAnalytics({
      event: 'application.submitted',
      payload: {
        offerId: offer.id,
        candidateId: candidate.id
      }
    });
    return application;
  }

  findById(id: string): Application {
    const application = this.db.getApplication(id);
    if (!application) {
      throw new NotFoundException('Application not found');
    }
    return application;
  }

  async updateStatus(id: string, dto: UpdateApplicationStatusDto) {
    const application = this.findById(id);
    const updated: Application = {
      ...application,
      status: dto.status
    };
    this.db.upsertApplication(updated);
    await this.coordinatorService.enqueueAnalytics({
      event: 'application.status_changed',
      payload: {
        applicationId: id,
        status: dto.status
      }
    });
    return updated;
  }
}
