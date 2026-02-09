import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/auth/models/auth_service.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/features/calendar/repositories/calendar_repository.dart';
import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/cover_letter/repositories/cover_letter_repository.dart';
import 'package:opti_job_app/features/cover_letter/services/cover_letter_service.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';
import 'package:opti_job_app/features/video_curriculum/services/video_curriculum_service.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/curriculum/services/curriculum_service.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/models/profile_service.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';
import 'package:opti_job_app/modules/candidates/repositories/candidates_repository.dart';
import 'package:opti_job_app/modules/candidates/data/repositories/firebase_candidates_repository.dart';
import 'package:opti_job_app/modules/companies/repositories/companies_repository.dart';
import 'package:opti_job_app/modules/companies/data/repositories/firebase_companies_repository.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/applicants/data/repositories/firebase_applicants_repository.dart';

class AppDependencies {
  AppDependencies._({
    required this.authRepository,
    required this.jobOfferRepository,
    required this.profileRepository,
    required this.candidatesRepository,
    required this.companiesRepository,
    required this.applicantsRepository,
    required this.curriculumRepository,
    required this.calendarRepository,
    required this.applicationRepository,
    required this.applicationService,
    required this.aiRepository,
    required this.coverLetterRepository,
    required this.videoCurriculumRepository,
  });

  factory AppDependencies.create({FirebaseFirestore? firestore}) {
    final firestoreInstance = firestore ?? FirebaseFirestore.instance;

    final authRepository = AuthRepository(AuthService());
    final jobOfferRepository = JobOfferRepository(JobOfferService());
    final profileRepository = ProfileRepository(ProfileService());
    final curriculumRepository = CurriculumRepository(CurriculumService());
    final calendarRepository = CalendarRepository();
    final applicationRepository = ApplicationRepository(
      firestore: firestoreInstance,
    );
    final applicationService = ApplicationService(
      applicationRepository: applicationRepository,
    );
    final candidatesRepository = FirebaseCandidatesRepository(
      firestore: firestoreInstance,
    );
    final companiesRepository = FirebaseCompaniesRepository(
      firestore: firestoreInstance,
    );
    final applicantsRepository = FirebaseApplicantsRepository(
      firestore: firestoreInstance,
    );
    final aiRepository = AiRepository(AiService());
    final coverLetterRepository = CoverLetterRepository(
      CoverLetterService(firestore: firestoreInstance),
    );
    final videoCurriculumRepository = VideoCurriculumRepository(
      VideoCurriculumService(firestore: firestoreInstance),
    );

    if (kDebugMode) {
      debugPrint(
        'Locator: AuthRepository, JobOfferRepository, ProfileRepository, '
        'CalendarRepository, ApplicationRepository, ApplicationService, '
        'CoverLetterRepository, VideoCurriculumRepository',
      );
      debugPrint('Firebase instances: firestore=$firestoreInstance');
    }

    return AppDependencies._(
      authRepository: authRepository,
      jobOfferRepository: jobOfferRepository,
      profileRepository: profileRepository,
      candidatesRepository: candidatesRepository,
      companiesRepository: companiesRepository,
      applicantsRepository: applicantsRepository,
      curriculumRepository: curriculumRepository,
      calendarRepository: calendarRepository,
      applicationRepository: applicationRepository,
      applicationService: applicationService,
      aiRepository: aiRepository,
      coverLetterRepository: coverLetterRepository,
      videoCurriculumRepository: videoCurriculumRepository,
    );
  }

  final AuthRepository authRepository;
  final JobOfferRepository jobOfferRepository;
  final ProfileRepository profileRepository;
  final CandidatesRepository candidatesRepository;
  final CompaniesRepository companiesRepository;
  final ApplicantsRepository applicantsRepository;
  final CurriculumRepository curriculumRepository;
  final CalendarRepository calendarRepository;
  final ApplicationRepository applicationRepository;
  final ApplicationService applicationService;
  final AiRepository aiRepository;
  final CoverLetterRepository coverLetterRepository;
  final VideoCurriculumRepository videoCurriculumRepository;
}
