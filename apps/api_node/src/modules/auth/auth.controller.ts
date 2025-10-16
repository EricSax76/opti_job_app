import { Body, Controller, Get, Headers, Post } from '@nestjs/common';

import { ensureBearer, AUTH_HEADER } from '@infojobs/shared-config';

import { AuthService } from './auth.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RefreshTokenDto } from './dto/refresh-token.dto.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  async login(@Body() dto: LoginDto) {
    const payload = await this.authService.validateLogin(
      dto.email,
      dto.password,
      dto.role
    );
    return this.authService.issueTokens(payload);
  }

  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Get('me')
  me(@Headers(AUTH_HEADER) authorization?: string) {
    const bearer = ensureBearer(authorization);
    if (!bearer) {
      return null;
    }
    const token = bearer.replace('Bearer ', '');
    return this.authService.getProfile(token);
  }
}
