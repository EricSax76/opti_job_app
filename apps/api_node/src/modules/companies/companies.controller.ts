import { Body, Controller, Get, Param, Post } from '@nestjs/common';

import { CompaniesService } from './companies.service.js';
import { CreateCompanyDto } from './dto/create-company.dto.js';

@Controller('companies')
export class CompaniesController {
  constructor(private readonly companiesService: CompaniesService) {}

  @Post()
  create(@Body() dto: CreateCompanyDto) {
    return this.companiesService.create(dto);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.companiesService.findById(id);
  }
}
