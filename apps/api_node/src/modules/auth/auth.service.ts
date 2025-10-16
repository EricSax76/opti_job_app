import { Inject, Injectable, Logger, OnModuleInit, UnauthorizedException } from '@nestjs/common';
import { compare, hash } from 'bcryptjs';
import { randomUUID } from 'node:crypto';
import { sign, verify } from 'jsonwebtoken';
import type { AppConfig } from '@infojobs/shared-config';

import { APP_CONFIG } from '../../common/config/app-config.provider.js';
import { InMemoryDatabase } from '../../common/database/in-memory.database.js';

type SupportedRole = 'candidate' | 'recruiter' | 'admin';

interface Credential {
  email: string;
  passwordHash: string;
  role: SupportedRole;
  entityId: string;
}

interface AuthPayload {
  sub: string;
  role: SupportedRole;
  email: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class AuthService implements OnModuleInit {
  private readonly logger = new Logger(AuthService.name);
  private readonly credentials = new Map<string, Credential>();
  private readonly refreshIndex = new Map<string, string>();

  constructor(
    @Inject(APP_CONFIG) private readonly config: AppConfig,
    private readonly db: InMemoryDatabase
  ) {}

  async onModuleInit() {
    // Seed default admin if not present
    const key = this.buildKey('admin', 'admin@infojobs.local');
    if (!this.credentials.has(key)) {
      await this.registerCredential({
        email: 'admin@infojobs.local',
        password: 'admin123',
        role: 'admin',
        entityId: 'admin_default'
      });
      this.logger.log('Seeded default admin admin@infojobs.local / admin123');
    }
  }

  async registerCredential(params: {
    email: string;
    password: string;
    role: SupportedRole;
    entityId: string;
  }) {
    const email = params.email.toLowerCase();
    const key = this.buildKey(params.role, email);
    const passwordHash = await hash(params.password, 10);
    this.credentials.set(key, {
      email,
      passwordHash,
      role: params.role,
      entityId: params.entityId
    });
  }

  async validateLogin(
    email: string,
    password: string,
    role: SupportedRole
  ): Promise<AuthPayload> {
    const key = this.buildKey(role, email.toLowerCase());
    const credential = this.credentials.get(key);
    if (!credential) {
      throw new UnauthorizedException('Invalid credentials');
    }
    const isValid = await compare(password, credential.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return {
      sub: credential.entityId,
      role: credential.role,
      email: credential.email
    };
  }

  issueTokens(payload: AuthPayload): AuthTokens {
    const accessToken = sign(payload, this.config.jwtSecret, {
      expiresIn: '15m'
    });
    const refreshToken = sign(
      { sub: payload.sub, role: payload.role, tokenType: 'refresh' },
      this.config.jwtSecret,
      { expiresIn: '7d' }
    );
    this.refreshIndex.set(refreshToken, payload.sub);
    return { accessToken, refreshToken, expiresIn: 900 };
  }

  refresh(refreshToken: string): AuthTokens {
    try {
      const decoded = verify(refreshToken, this.config.jwtSecret) as {
        sub: string;
        role: SupportedRole;
        tokenType?: string;
      };
      if (decoded.tokenType !== 'refresh') {
        throw new UnauthorizedException('Invalid refresh token');
      }
      if (!this.refreshIndex.has(refreshToken)) {
        throw new UnauthorizedException('Refresh token revoked');
      }
      const key = this.findCredentialKey(decoded.sub, decoded.role);
      if (!key) {
        throw new UnauthorizedException('Account not found');
      }
      const credential = this.credentials.get(key)!;
      return this.issueTokens({
        sub: decoded.sub,
        role: credential.role,
        email: credential.email
      });
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  revoke(refreshToken: string) {
    this.refreshIndex.delete(refreshToken);
  }

  getProfile(token: string) {
    try {
      const payload = verify(token, this.config.jwtSecret) as AuthPayload;
      return {
        ...payload,
        profile: this.resolveProfile(payload)
      };
    } catch {
      throw new UnauthorizedException('Invalid token');
    }
  }

  private resolveProfile(payload: AuthPayload) {
    if (payload.role === 'candidate') {
      return this.db.getCandidate(payload.sub);
    }
    if (payload.role === 'recruiter') {
      const recruiter = this.db.getRecruiter(payload.sub);
      if (!recruiter) {
        return null;
      }
      const company = this.db.getCompany(recruiter.companyId);
      if (!company) {
        return recruiter;
      }
      return {
        ...company,
        recruiterId: recruiter.id
      };
    }
    if (payload.role === 'admin') {
      return { id: payload.sub, email: payload.email };
    }
    return null;
  }

  private buildKey(role: SupportedRole, email: string) {
    return `${role}:${email}`;
  }

  private findCredentialKey(entityId: string, role: SupportedRole) {
    for (const [key, cred] of this.credentials.entries()) {
      if (cred.entityId === entityId && cred.role === role) {
        return key;
      }
    }
    return null;
  }

  generateApiKey() {
    return `api_${randomUUID()}`;
  }
}
