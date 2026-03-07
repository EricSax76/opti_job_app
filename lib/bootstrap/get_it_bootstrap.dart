import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:opti_job_app/auth/models/auth_service.dart';
import 'package:opti_job_app/auth/services/eudi_wallet_native_channel.dart';
import 'package:opti_job_app/features/ai/api/firebase_ai_client.dart';
import 'package:opti_job_app/modules/curriculum/services/cv_analysis_service.dart';
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
import 'package:opti_job_app/modules/analytics/repositories/analytics_repository.dart';
import 'package:opti_job_app/modules/analytics/repositories/firebase_analytics_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/compliance/repositories/firebase_compliance_repository.dart';
import 'package:opti_job_app/modules/companies/repositories/companies_repository.dart';
import 'package:opti_job_app/modules/companies/repositories/firebase_companies_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/curriculum/services/curriculum_service.dart';
import 'package:opti_job_app/modules/interviews/repositories/firebase_interview_repository.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/job_offers/data/services/job_offer_read_service.dart';
import 'package:opti_job_app/modules/job_offers/data/services/job_offer_write_service.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/models/profile_service.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';
import 'package:opti_job_app/modules/recruiters/repositories/firebase_recruiter_repository.dart';
import 'package:opti_job_app/modules/recruiters/repositories/recruiter_repository.dart';
import 'package:opti_job_app/modules/recruiters/services/invitation_service.dart';
import 'package:opti_job_app/modules/recruiters/services/rbac_service.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/firebase_talent_pool_repository.dart';
import 'package:opti_job_app/modules/talent_pool/repositories/talent_pool_repository.dart';
import 'package:opti_job_app/modules/ats/repositories/firebase_pipeline_repository.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';

void setupGetIt({
  FirebaseFirestore? firestore,
  FirebaseStorage? storage,
  FirebaseFunctions? functions,
  FirebaseFunctions? fallbackFunctions,
  FirebaseAuth? auth,
  FirebaseAI? firebaseAI,
}) {
  final getIt = GetIt.instance;
  final firestoreInstance = firestore ?? FirebaseFirestore.instance;
  final storageInstance = storage ?? FirebaseStorage.instance;
  final functionsInstance =
      functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');
  final fallbackFunctionsInstance =
      fallbackFunctions ?? FirebaseFunctions.instance;
  final authInstance = auth ?? FirebaseAuth.instance;
  final firebaseAIInstance = firebaseAI ?? _createFirebaseAI(authInstance);

  // External
  getIt.registerSingleton<FirebaseFirestore>(firestoreInstance);
  getIt.registerSingleton<FirebaseStorage>(storageInstance);
  getIt.registerSingleton<FirebaseAuth>(authInstance);
  getIt.registerSingleton<FirebaseAI>(firebaseAIInstance);

  // Auth
  getIt.registerLazySingleton<EudiWalletNativeChannel>(
    () => MethodChannelEudiWalletNativeChannel(),
  );
  getIt.registerLazySingleton(
    () => AuthService(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
      functions: functionsInstance,
      fallbackFunctions: fallbackFunctionsInstance,
      eudiWalletNativeChannel: getIt<EudiWalletNativeChannel>(),
    ),
  );
  getIt.registerLazySingleton(() => AuthRepository(getIt<AuthService>()));

  // Job Offers
  getIt.registerLazySingleton(
    () => JobOfferReadService(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(
    () => JobOfferWriteService(
      functions: functionsInstance,
      fallbackFunctions: fallbackFunctionsInstance,
    ),
  );
  getIt.registerLazySingleton(
    () => JobOfferRepository(
      getIt<JobOfferReadService>(),
      getIt<JobOfferWriteService>(),
    ),
  );

  // Profiles
  getIt.registerLazySingleton(
    () => ProfileService(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );
  getIt.registerLazySingleton(() => ProfileRepository(getIt<ProfileService>()));

  // Curriculum
  getIt.registerLazySingleton(
    () => CurriculumService(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );
  getIt.registerLazySingleton(
    () => CurriculumRepository(getIt<CurriculumService>()),
  );
  getIt.registerLazySingleton(
    () => CvAnalysisService(aiClient: getIt<FirebaseAiClient>()),
  );

  // Calendar
  getIt.registerLazySingleton(
    () => CalendarRepository(
      firestore: getIt<FirebaseFirestore>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
  );

  // Application
  getIt.registerLazySingleton(
    () => ApplicationRepository(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(
    () => ApplicationService(
      applicationRepository: getIt<ApplicationRepository>(),
      functions: functionsInstance,
      fallbackFunctions: fallbackFunctionsInstance,
    ),
  );

  // Companies
  getIt.registerLazySingleton<CompaniesRepository>(
    () => FirebaseCompaniesRepository(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );

  // Applicants
  getIt.registerLazySingleton<ApplicantsRepository>(
    () => FirebaseApplicantsRepository(firestore: getIt<FirebaseFirestore>()),
  );

  // AI
  getIt.registerLazySingleton<FirebaseAiClient>(
    () => FirebaseAiClient(
      firebaseAI: getIt<FirebaseAI>(),
      auth: getIt<FirebaseAuth>(),
    ),
  );
  getIt.registerLazySingleton(
    () => AiService(client: getIt<FirebaseAiClient>()),
  );
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
    () => VideoCurriculumService(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<FirebaseStorage>(),
    ),
  );
  getIt.registerLazySingleton(
    () => VideoCurriculumRepository(getIt<VideoCurriculumService>()),
  );

  // Interviews
  getIt.registerLazySingleton<InterviewRepository>(
    () => FirebaseInterviewRepository(
      firestore: getIt<FirebaseFirestore>(),
      functions: functionsInstance,
      fallbackFunctions: fallbackFunctionsInstance,
    ),
  );

  // Compliance
  getIt.registerLazySingleton<FirebaseComplianceRepository>(
    () => FirebaseComplianceRepository(
      firestore: getIt<FirebaseFirestore>(),
      functions: functionsInstance,
      fallbackFunctions: fallbackFunctionsInstance,
    ),
  );
  getIt.registerLazySingleton<AuditRepository>(
    () => getIt<FirebaseComplianceRepository>(),
  );
  getIt.registerLazySingleton<DataRequestRepository>(
    () => getIt<FirebaseComplianceRepository>(),
  );
  getIt.registerLazySingleton<ConsentRepository>(
    () => getIt<FirebaseComplianceRepository>(),
  );
  getIt.registerLazySingleton<SalaryBenchmarkRepository>(
    () => getIt<FirebaseComplianceRepository>(),
  );

  // Analytics
  getIt.registerLazySingleton<AnalyticsRepository>(
    () => FirebaseAnalyticsRepository(firestore: getIt<FirebaseFirestore>()),
  );

  // Recruiters (Fase 0 RBAC)
  getIt.registerLazySingleton<RecruiterRepository>(
    () => FirebaseRecruiterRepository(
      firestore: getIt<FirebaseFirestore>(),
      functions: functionsInstance,
      fallbackFunctions: fallbackFunctionsInstance,
    ),
  );
  getIt.registerLazySingleton(
    () => InvitationService(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton(() => const RbacService());

  // Talent Pool
  getIt.registerLazySingleton<TalentPoolRepository>(
    () => FirebaseTalentPoolRepository(
      firestore: getIt<FirebaseFirestore>(),
      functions: functionsInstance,
      fallbackFunctions: fallbackFunctionsInstance,
    ),
  );

  // ATS (Fase 2 Pipeline)
  getIt.registerLazySingleton<PipelineRepository>(
    () => FirebasePipelineRepository(firestore: getIt<FirebaseFirestore>()),
  );
}

FirebaseAI _createFirebaseAI(FirebaseAuth auth) {
  const backend = String.fromEnvironment(
    'FIREBASE_AI_BACKEND',
    defaultValue: 'vertex',
  ); // 'vertex' | 'google'
  const useAppCheck = bool.fromEnvironment(
    'USE_FIREBASE_APP_CHECK',
    defaultValue: false,
  );
  final appCheck = useAppCheck ? FirebaseAppCheck.instance : null;

  if (backend == 'google') {
    return FirebaseAI.googleAI(auth: auth, appCheck: appCheck);
  }

  const location = String.fromEnvironment(
    'FIREBASE_AI_LOCATION',
    defaultValue: 'europe-southwest1',
  );
  return FirebaseAI.vertexAI(
    auth: auth,
    location: location,
    appCheck: appCheck,
  );
}
