import { Injectable, NotFoundException } from '@nestjs/common';
import type { MatchingScore, Offer } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { CoordinatorService } from '../../agents/coordinator/coordinator.service.js';
import { generateId } from '../../common/utils/id.util.js';
import { CreateOfferDto } from './dto/create-offer.dto.js';

@Injectable()
export class OffersService {
  constructor(
    private readonly db: InMemoryDatabase,
    private readonly coordinatorService: CoordinatorService
  ) {}

  async create(dto: CreateOfferDto): Promise<Offer> {
    const company = this.db.getCompany(dto.companyId);
    if (!company) {
      throw new NotFoundException('Company not found');
    }
    const offer: Offer = {
      id: generateId('ofr'),
      companyId: company.id,
      title: dto.title,
      description: dto.description,
      skills: dto.skills,
      seniority: dto.seniority,
      location: dto.location,
      remote: dto.remote,
      status: 'published',
      createdAt: new Date().toISOString()
    };
    this.db.upsertOffer(offer);
    await this.coordinatorService.offerCreated(offer, 100);
    return offer;
  }

  findById(id: string): Offer {
    const offer = this.db.getOffer(id);
    if (!offer) {
      throw new NotFoundException('Offer not found');
    }
    return offer;
  }

  findAll(seniority?: string): Offer[] {
    const offers = this.db.listOffers();
    if (!seniority) {
      return offers;
    }
    return offers.filter((offer) => offer.seniority === seniority);
  }

  listCandidates(offerId: string, top = 50): MatchingScore[] {
    return this.db.listRankingByOffer(offerId, top);
  }

  async refreshMatching(offerId: string, top = 50) {
    this.findById(offerId);
    await this.coordinatorService.enqueueMatchingCompute({ offerId, top });
    return { status: 'queued' };
  }
}
