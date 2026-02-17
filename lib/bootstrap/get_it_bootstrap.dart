import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:opti_job_app/auth/models/auth_service.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/features/calendar/repositories/calendar_repository.dart';
import 'package:opti_job_app/features/cover_letter/repositories/cover_letter_repository.dart';
import 'package:opti_job_app/features/cover_letter/services/cover_letter_service.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';
import 'package:opti_job_app/features/video_curriculum/services/video_curriculum_service.dart';
import 'package:opti_job_app/modules/applicants/data/repositories/firebase_applicants_repository.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/companies/repositories/companies_repository.dart';
import 'package:opti_job_app/modules/companies/repositories/firebase_companies_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/curriculum/services/curriculum_service.dart';
import 'package:opti_job_app/modules/interviews/repositories/firebase_interview_repository.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/models/profile_service.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

void setupGetIt({FirebaseFirestore? firestore}) {
  final getIt = GetIt.instance;
  final firestoreInstance = firestore ?? FirebaseFirestore.instance;

  // External
  getIt.registerSingleton<FirebaseFirestore>(firestoreInstance);

  // Auth
  getIt.registerLazySingleton(() => AuthService());
  getIt.registerLazySingleton(() => AuthRepository(getIt<AuthService>()));

  // Job Offers
  getIt.registerLazySingleton(() => JobOfferService());
  getIt.registerLazySingleton(
    () => JobOfferRepository(getIt<JobOfferService>()),
  );

  // Profiles
  getIt.registerLazySingleton(() => ProfileService());
  getIt.registerLazySingleton(
    () => ProfileRepository(getIt<ProfileService>()),
  );

  // Curriculum
  getIt.registerLazySingleton(() => CurriculumService());
  getIt.registerLazySingleton(
    () => CurriculumRepository(getIt<CurriculumService>()),
  );

  // Calendar
  getIt.registerLazySingleton(() => CalendarRepository());

  // Application
  getIt.registerLazySingleton(
    () => ApplicationRepository(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(
    () => ApplicationService(
      applicationRepository: getIt<ApplicationRepository>(),
    ),
  );

  // Companies
  getIt.registerLazySingleton<CompaniesRepository>(
    () => FirebaseCompaniesRepository(firestore: getIt<FirebaseFirestore>()),
  );

  // Applicants
  getIt.registerLazySingleton<ApplicantsRepository>(
    () => FirebaseApplicantsRepository(firestore: getIt<FirebaseFirestore>()),
  );

  // AI
  getIt.registerLazySingleton(() => AiService());
  getIt.registerLazySingleton(() => AiRepository(getIt<AiService>()));

  // Cover Letter
  getIt.registerLazySingleton(
    () => CoverLetterService(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(
    () => CoverLetterRepository(getIt<CoverLetterService>()),
  );

  // Video Curriculum
  getIt.registerLazySingleton(
    () => VideoCurriculumService(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(
    () => VideoCurriculumRepository(getIt<VideoCurriculumService>()),
  );

  // Interviews
  getIt.registerLazySingleton<InterviewRepository>(
    () => FirebaseInterviewRepository(firestore: getIt<FirebaseFirestore>()),
  );
}
