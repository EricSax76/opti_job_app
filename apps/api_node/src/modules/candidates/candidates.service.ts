import { Injectable, NotFoundException } from '@nestjs/common';
import type { Candidate } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { AuthService } from '../auth/auth.service.js';
import { generateId } from '../../common/utils/id.util.js';
import { CreateCandidateDto } from './dto/create-candidate.dto.js';
import { UploadCvDto } from './dto/upload-cv.dto.js';

@Injectable()
export class CandidatesService {
  constructor(
    private readonly db: InMemoryDatabase,
    private readonly authService: AuthService
  ) {}

  async create(dto: CreateCandidateDto): Promise<Candidate> {
    const candidate: Candidate = {
      id: generateId('cand'),
      name: dto.name,
      email: dto.email.toLowerCase(),
      headline: dto.headline,
      location: dto.location,
      skills: dto.skills ?? [],
      createdAt: new Date().toISOString()
    };
    this.db.upsertCandidate(candidate);
    await this.authService.registerCredential({
      email: dto.email,
      password: dto.password,
      role: 'candidate',
      entityId: candidate.id
    });
    return candidate;
  }

  findById(id: string): Candidate {
    const candidate = this.db.getCandidate(id);
    if (!candidate) {
      throw new NotFoundException('Candidate not found');
    }
    return candidate;
  }

  uploadCv(id: string, dto: UploadCvDto): Candidate {
    const candidate = this.db.getCandidate(id);
    if (!candidate) {
      throw new NotFoundException('Candidate not found');
    }
    const updated: Candidate = {
      ...candidate,
      cvUrl: dto.url
    };
    this.db.upsertCandidate(updated);
    return updated;
  }
}
