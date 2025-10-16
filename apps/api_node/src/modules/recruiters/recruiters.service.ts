import { Injectable, NotFoundException } from '@nestjs/common';
import type { Recruiter } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { AuthService } from '../auth/auth.service.js';
import { generateId } from '../../common/utils/id.util.js';
import { CreateRecruiterDto } from './dto/create-recruiter.dto.js';

@Injectable()
export class RecruitersService {
  constructor(
    private readonly db: InMemoryDatabase,
    private readonly authService: AuthService
  ) {}

  async create(dto: CreateRecruiterDto): Promise<Recruiter> {
    const company = this.db.getCompany(dto.companyId);
    if (!company) {
      throw new NotFoundException('Company not found');
    }
    const recruiter: Recruiter = {
      id: generateId('rec'),
      companyId: company.id,
      name: dto.name,
      email: dto.email.toLowerCase(),
      createdAt: new Date().toISOString()
    };
    this.db.upsertRecruiter(recruiter);
    await this.authService.registerCredential({
      email: dto.email,
      password: dto.password,
      role: 'recruiter',
      entityId: recruiter.id
    });
    return recruiter;
  }

  findById(id: string) {
    const recruiter = this.db.getRecruiter(id);
    if (!recruiter) {
      throw new NotFoundException('Recruiter not found');
    }
    return recruiter;
  }
}
