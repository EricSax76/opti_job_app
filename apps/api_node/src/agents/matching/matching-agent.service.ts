import { Injectable, Logger } from '@nestjs/common';
import type {
  Candidate,
  MatchingComputeJob,
  MatchingUpdateJob,
  Offer
} from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { CoordinatorService } from '../coordinator/coordinator.service.js';

@Injectable()
export class MatchingAgentService {
  private readonly logger = new Logger(MatchingAgentService.name);

  constructor(
    private readonly db: InMemoryDatabase,
    private readonly coordinatorService: CoordinatorService
  ) {}

  async processCompute(job: MatchingComputeJob) {
    const offer = this.db.getOffer(job.offerId);
    if (!offer) {
      this.logger.warn(`Offer ${job.offerId} not found`);
      return;
    }

    const candidates = this.db.listCandidates();
    const scores = candidates
      .map((candidate) => ({
        candidate,
        score: this.computeScore(offer, candidate)
      }))
      .filter((item) => item.score > 0)
      .sort((a, b) => b.score - a.score);

    const top = job.top ?? 50;
    scores.slice(0, top).forEach((item, index) => {
      this.db.upsertMatchingScore({
        offerId: offer.id,
        candidateId: item.candidate.id,
        score: item.score,
        rank: index + 1
      });
    });

    await this.coordinatorService.matchingComputed(
      offer.id,
      scores.slice(0, top).map((item) => item.candidate.id)
    );
  }

  async processUpdate(job: MatchingUpdateJob) {
    await this.processCompute({ offerId: job.offerId, top: 50 });
  }

  private computeScore(offer: Offer, candidate: Candidate): number {
    let score = 0;
    const skillMatch = candidate.skills.filter((skill) =>
      offer.skills.some((offerSkill) =>
        offerSkill.toLowerCase() === skill.toLowerCase()
      )
    );
    score += skillMatch.length * 10;

    if (offer.location && candidate.location) {
      if (offer.location === candidate.location) {
        score += 15;
      }
    }

    if (offer.remote) {
      score += 5;
    }

    return score;
  }
}
