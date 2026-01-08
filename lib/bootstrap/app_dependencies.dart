import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/auth/models/auth_service.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/features/calendar/repositories/calendar_repository.dart';
import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/aplications/models/application_service.dart';
import 'package:opti_job_app/modules/aplications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_service.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/models/profile_service.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class AppDependencies {
  AppDependencies._({
    required this.authRepository,
    required this.jobOfferRepository,
    required this.profileRepository,
    required this.curriculumRepository,
    required this.calendarRepository,
    required this.applicationRepository,
    required this.applicationService,
    required this.aiRepository,
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
    final aiRepository = AiRepository(AiService());

    if (kDebugMode) {
      debugPrint(
        'Locator: AuthRepository, JobOfferRepository, ProfileRepository, '
        'CalendarRepository, ApplicationRepository, ApplicationService',
      );
      debugPrint('Firebase instances: firestore=$firestoreInstance');
    }

    return AppDependencies._(
      authRepository: authRepository,
      jobOfferRepository: jobOfferRepository,
      profileRepository: profileRepository,
      curriculumRepository: curriculumRepository,
      calendarRepository: calendarRepository,
      applicationRepository: applicationRepository,
      applicationService: applicationService,
      aiRepository: aiRepository,
    );
  }

  final AuthRepository authRepository;
  final JobOfferRepository jobOfferRepository;
  final ProfileRepository profileRepository;
  final CurriculumRepository curriculumRepository;
  final CalendarRepository calendarRepository;
  final ApplicationRepository applicationRepository;
  final ApplicationService applicationService;
  final AiRepository aiRepository;
}
