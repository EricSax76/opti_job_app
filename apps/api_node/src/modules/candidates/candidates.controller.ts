import { Body, Controller, Get, Param, Post } from '@nestjs/common';

import { CandidatesService } from './candidates.service.js';
import { CreateCandidateDto } from './dto/create-candidate.dto.js';
import { UploadCvDto } from './dto/upload-cv.dto.js';

@Controller('candidates')
export class CandidatesController {
  constructor(private readonly candidatesService: CandidatesService) {}

  @Post()
  create(@Body() dto: CreateCandidateDto) {
    return this.candidatesService.create(dto);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.candidatesService.findById(id);
  }

  @Post(':id/cv')
  uploadCv(@Param('id') id: string, @Body() dto: UploadCvDto) {
    return this.candidatesService.uploadCv(id, dto);
  }
}
