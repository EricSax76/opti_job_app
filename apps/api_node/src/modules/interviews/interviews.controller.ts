import { Body, Controller, Get, Param, Post } from '@nestjs/common';

import { InterviewsService } from './interviews.service.js';
import { CreateInterviewDto } from './dto/create-interview.dto.js';
import { RescheduleInterviewDto } from './dto/reschedule-interview.dto.js';

@Controller('interviews')
export class InterviewsController {
  constructor(private readonly interviewsService: InterviewsService) {}

  @Post()
  create(@Body() dto: CreateInterviewDto) {
    return this.interviewsService.create(dto);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.interviewsService.findById(id);
  }

  @Post(':id/reschedule')
  reschedule(@Param('id') id: string, @Body() dto: RescheduleInterviewDto) {
    return this.interviewsService.reschedule(id, dto);
  }
}
