import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';

import { OffersService } from './offers.service.js';
import { CreateOfferDto } from './dto/create-offer.dto.js';
import { RefreshMatchingDto } from './dto/refresh-matching.dto.js';

@Controller('offers')
export class OffersController {
  constructor(private readonly offersService: OffersService) {}

  @Post()
  create(@Body() dto: CreateOfferDto) {
    return this.offersService.create(dto);
  }

  @Get()
  findAll(@Query('seniority') seniority?: string) {
    return this.offersService.findAll(seniority);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.offersService.findById(id);
  }

  @Get(':id/candidates')
  listCandidates(@Param('id') id: string, @Query('top') top?: string) {
    const limit = top ? Number(top) : undefined;
    return this.offersService.listCandidates(id, limit);
  }

  @Post(':id/match/refresh')
  refresh(@Param('id') id: string, @Body() body: RefreshMatchingDto) {
    return this.offersService.refreshMatching(id, body.top);
  }
}
