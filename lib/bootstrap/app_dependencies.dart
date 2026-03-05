import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/calendar/repositories/calendar_repository.dart';
import 'package:opti_job_app/features/cover_letter/repositories/cover_letter_repository.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/analytics/repositories/analytics_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/companies/repositories/companies_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';
import 'package:opti_job_app/modules/curriculum/services/cv_analysis_service.dart';
import 'package:opti_job_app/modules/recruiters/repositories/recruiter_repository.dart';
import 'package:opti_job_app/modules/recruiters/services/invitation_service.dart';
import 'package:opti_job_app/modules/recruiters/services/rbac_service.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';

class AppDependencies {
  AppDependencies._({
    required this.authRepository,
    required this.jobOfferRepository,
    required this.profileRepository,
    required this.companiesRepository,
    required this.applicantsRepository,
    required this.curriculumRepository,
    required this.cvAnalysisService,
    required this.calendarRepository,
    required this.applicationRepository,
    required this.applicationService,
    required this.aiService,
    required this.aiRepository,
    required this.coverLetterRepository,
    required this.videoCurriculumRepository,
    required this.interviewRepository,
    required this.dataRequestRepository,
    required this.consentRepository,
    required this.analyticsRepository,
    required this.firebaseAuth,
    required this.recruiterRepository,
    required this.invitationService,
    required this.rbacService,
    required this.pipelineRepository,
  });

  factory AppDependencies.create() {
    final getIt = GetIt.instance;

    if (kDebugMode) {
      debugPrint('AppDependencies: Resolving dependencies from GetIt');
    }

    return AppDependencies._(
      authRepository: getIt<AuthRepository>(),
      jobOfferRepository: getIt<JobOfferRepository>(),
      profileRepository: getIt<ProfileRepository>(),
      companiesRepository: getIt<CompaniesRepository>(),
      applicantsRepository: getIt<ApplicantsRepository>(),
      curriculumRepository: getIt<CurriculumRepository>(),
      cvAnalysisService: getIt<CvAnalysisService>(),
      calendarRepository: getIt<CalendarRepository>(),
      applicationRepository: getIt<ApplicationRepository>(),
      applicationService: getIt<ApplicationService>(),
      aiService: getIt<AiService>(),
      aiRepository: getIt<AiRepository>(),
      coverLetterRepository: getIt<CoverLetterRepository>(),
      videoCurriculumRepository: getIt<VideoCurriculumRepository>(),
      interviewRepository: getIt<InterviewRepository>(),
      dataRequestRepository: getIt<DataRequestRepository>(),
      consentRepository: getIt<ConsentRepository>(),
      analyticsRepository: getIt<AnalyticsRepository>(),
      firebaseAuth: getIt<FirebaseAuth>(),
      recruiterRepository: getIt<RecruiterRepository>(),
      invitationService: getIt<InvitationService>(),
      rbacService: getIt<RbacService>(),
      pipelineRepository: getIt<PipelineRepository>(),
    );
  }

  final AuthRepository authRepository;
  final JobOfferRepository jobOfferRepository;
  final ProfileRepository profileRepository;
  final CompaniesRepository companiesRepository;
  final ApplicantsRepository applicantsRepository;
  final CurriculumRepository curriculumRepository;
  final CvAnalysisService cvAnalysisService;
  final CalendarRepository calendarRepository;
  final ApplicationRepository applicationRepository;
  final ApplicationService applicationService;
  final AiService aiService;
  final AiRepository aiRepository;
  final CoverLetterRepository coverLetterRepository;
  final VideoCurriculumRepository videoCurriculumRepository;
  final InterviewRepository interviewRepository;
  final DataRequestRepository dataRequestRepository;
  final ConsentRepository consentRepository;
  final AnalyticsRepository analyticsRepository;
  final FirebaseAuth firebaseAuth;

  // Fase 0 RBAC
  final RecruiterRepository recruiterRepository;
  final InvitationService invitationService;
  final RbacService rbacService;
  final PipelineRepository pipelineRepository;
}
