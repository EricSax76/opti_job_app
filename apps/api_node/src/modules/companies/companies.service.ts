import { Injectable, NotFoundException } from '@nestjs/common';
import type { Company } from '@infojobs/shared-types';

import { InMemoryDatabase } from '../../common/database/in-memory.database.js';
import { AuthService } from '../auth/auth.service.js';
import { generateId } from '../../common/utils/id.util.js';
import { CreateCompanyDto } from './dto/create-company.dto.js';

@Injectable()
export class CompaniesService {
  constructor(
    private readonly db: InMemoryDatabase,
    private readonly authService: AuthService
  ) {}

  async create(dto: CreateCompanyDto): Promise<Company> {
    const now = new Date().toISOString();
    const company: Company = {
      id: generateId('cmp'),
      name: dto.name,
      email: dto.email.toLowerCase(),
      createdAt: now
    };
    this.db.upsertCompany(company);
    await this.authService.registerCredential({
      email: dto.email,
      password: dto.password,
      role: 'recruiter',
      entityId: company.id
    });
    return company;
  }

  findById(id: string): Company {
    const company = this.db.getCompany(id);
    if (!company) {
      throw new NotFoundException('Company not found');
    }
    return company;
  }
}
