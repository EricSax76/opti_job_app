import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppConfigProvider } from './common/config/app-config.provider.js';
import { HealthModule } from './modules/health/health.module.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { CompaniesModule } from './modules/companies/companies.module.js';
import { RecruitersModule } from './modules/recruiters/recruiters.module.js';
import { CandidatesModule } from './modules/candidates/candidates.module.js';
import { OffersModule } from './modules/offers/offers.module.js';
import { ApplicationsModule } from './modules/applications/applications.module.js';
import { InterviewsModule } from './modules/interviews/interviews.module.js';
import { SearchModule } from './modules/search/search.module.js';
import { CoordinatorModule } from './agents/coordinator/coordinator.module.js';
import { MatchingAgentModule } from './agents/matching/matching-agent.module.js';
import { CalendarsAgentModule } from './agents/calendars/calendars-agent.module.js';
import { NotificationsAgentModule } from './agents/notifications/notifications-agent.module.js';
import { AntifraudAgentModule } from './agents/antifraud/antifraud-agent.module.js';
import { AnalyticsAgentModule } from './agents/analytics/analytics-agent.module.js';
import { DatabaseModule } from './common/database/database.module.js';
import { QueuesModule } from './common/queues/queues.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    QueuesModule,
    HealthModule,
    AuthModule,
    CompaniesModule,
    RecruitersModule,
    CandidatesModule,
    OffersModule,
    ApplicationsModule,
    InterviewsModule,
    SearchModule,
    CoordinatorModule,
    MatchingAgentModule,
    CalendarsAgentModule,
    NotificationsAgentModule,
    AntifraudAgentModule,
    AnalyticsAgentModule
  ],
  providers: [AppConfigProvider]
})
export class AppModule {}
