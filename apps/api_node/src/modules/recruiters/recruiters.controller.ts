import { Body, Controller, Get, Param, Post } from '@nestjs/common';

import { CreateRecruiterDto } from './dto/create-recruiter.dto.js';
import { RecruitersService } from './recruiters.service.js';

@Controller('recruiters')
export class RecruitersController {
  constructor(private readonly recruitersService: RecruitersService) {}

  @Post()
  create(@Body() dto: CreateRecruiterDto) {
    return this.recruitersService.create(dto);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.recruitersService.findById(id);
  }
}
