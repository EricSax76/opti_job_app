import { Controller, Get, Query } from '@nestjs/common';

import { SearchService } from './search.service.js';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get('offers')
  searchOffers(
    @Query('q') q?: string,
    @Query('location') location?: string,
    @Query('seniority') seniority?: string
  ) {
    return this.searchService.searchOffers({ q, location, seniority });
  }

  @Get('candidates')
  searchCandidates(
    @Query('q') q?: string,
    @Query('location') location?: string
  ) {
    return this.searchService.searchCandidates({ q, location });
  }
}
