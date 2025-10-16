import { Injectable } from '@nestjs/common';
import {
  Application,
  Candidate,
  Company,
  Interview,
  MatchingScore,
  Offer,
  Recruiter
} from '@infojobs/shared-types';

@Injectable()
export class InMemoryDatabase {
  private readonly offers = new Map<string, Offer>();
  private readonly companies = new Map<string, Company>();
  private readonly candidates = new Map<string, Candidate>();
  private readonly recruiters = new Map<string, Recruiter>();
  private readonly applications = new Map<string, Application>();
  private readonly interviews = new Map<string, Interview>();
  private readonly matchingScores = new Map<string, MatchingScore>();

  upsertCompany(company: Company) {
    this.companies.set(company.id, company);
  }

  listCompanies() {
    return Array.from(this.companies.values());
  }

  getCompany(id: string) {
    return this.companies.get(id);
  }

  upsertRecruiter(recruiter: Recruiter) {
    this.recruiters.set(recruiter.id, recruiter);
  }

  listRecruitersByCompany(companyId: string) {
    return Array.from(this.recruiters.values()).filter(
      (recruiter) => recruiter.companyId === companyId
    );
  }

  getRecruiter(id: string) {
    return this.recruiters.get(id);
  }

  upsertCandidate(candidate: Candidate) {
    this.candidates.set(candidate.id, candidate);
  }

  listCandidates() {
    return Array.from(this.candidates.values());
  }

  getCandidate(id: string) {
    return this.candidates.get(id);
  }

  upsertOffer(offer: Offer) {
    this.offers.set(offer.id, offer);
  }

  listOffers() {
    return Array.from(this.offers.values());
  }

  getOffer(id: string) {
    return this.offers.get(id);
  }

  upsertApplication(application: Application) {
    this.applications.set(application.id, application);
  }

  listApplications() {
    return Array.from(this.applications.values());
  }

  getApplication(id: string) {
    return this.applications.get(id);
  }

  upsertInterview(interview: Interview) {
    this.interviews.set(interview.id, interview);
  }

  getInterview(id: string) {
    return this.interviews.get(id);
  }

  upsertMatchingScore(score: MatchingScore) {
    const key = `${score.offerId}:${score.candidateId}`;
    this.matchingScores.set(key, score);
  }

  listRankingByOffer(offerId: string, top = 50) {
    return Array.from(this.matchingScores.values())
      .filter((score) => score.offerId === offerId)
      .sort((a, b) => a.rank - b.rank)
      .slice(0, top);
  }
}
