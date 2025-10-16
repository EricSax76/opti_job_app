import { Injectable } from '@nestjs/common';
import type { Candidate, Offer } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';

@Injectable()
export class SearchService {
  constructor(private readonly db: InMemoryDatabase) {}

  searchOffers(query: {
    q?: string;
    location?: string;
    seniority?: string;
  }): Offer[] {
    return this.db
      .listOffers()
      .filter((offer) =>
        query.location ? offer.location === query.location : true
      )
      .filter((offer) =>
        query.seniority ? offer.seniority === query.seniority : true
      )
      .filter((offer) =>
        query.q
          ? offer.title.toLowerCase().includes(query.q.toLowerCase()) ||
            offer.skills.some((skill) =>
              skill.toLowerCase().includes(query.q!.toLowerCase())
            )
          : true
      );
  }

  searchCandidates(query: { q?: string; location?: string }): Candidate[] {
    return this.db
      .listCandidates()
      .filter((candidate) =>
        query.location ? candidate.location === query.location : true
      )
      .filter((candidate) =>
        query.q
          ? candidate.name.toLowerCase().includes(query.q.toLowerCase()) ||
            candidate.skills.some((skill) =>
              skill.toLowerCase().includes(query.q!.toLowerCase())
            )
          : true
      );
  }
}
