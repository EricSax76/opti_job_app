import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/ui/pages/candidate_login_screen.dart';
import 'package:opti_job_app/auth/ui/pages/candidate_register_screen.dart';
import 'package:opti_job_app/auth/ui/pages/company_login_screen.dart';
import 'package:opti_job_app/auth/ui/pages/company_register_screen.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';
import 'package:opti_job_app/features/onboarding/view/pages/onboarding_screen.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_dashboard_screen.dart';
import 'package:opti_job_app/home/pages/landing_screen.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_list_screen.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_detail_screen.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_template_cubit.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_dashboard_screen.dart';
import 'package:opti_job_app/modules/companies/cubits/company_profile_form_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_profile_screen.dart';
import 'package:opti_job_app/modules/companies/cubits/company_dashboard_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_pdf_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_share_service.dart';
import 'package:opti_job_app/modules/curriculum/services/cv_analysis_service.dart';
import 'package:opti_job_app/modules/applicants/ui/pages/applicant_curriculum_screen.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/analytics/cubits/analytics_dashboard_cubit.dart';
import 'package:opti_job_app/modules/analytics/repositories/analytics_repository.dart';
import 'package:opti_job_app/modules/analytics/ui/pages/analytics_dashboard_screen.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/compliance/cubits/data_requests_cubit.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart';
import 'package:opti_job_app/modules/compliance/ui/pages/consent_management_screen.dart';
import 'package:opti_job_app/modules/interviews/ui/pages/interview_chat_page.dart';

import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';
import 'package:opti_job_app/modules/recruiters/ui/pages/recruiter_dashboard_screen.dart';
import 'package:opti_job_app/modules/recruiters/ui/pages/recruiter_login_screen.dart';
import 'package:opti_job_app/modules/recruiters/ui/pages/recruiter_register_info_screen.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/features/calendar/repositories/calendar_repository.dart';

/// Listens to a stream and notifies GoRouter when auth state changes.
class GoRouterCombinedRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _candidateAuthSubscription;
  late final StreamSubscription<dynamic> _companyAuthSubscription;
  late final StreamSubscription<dynamic> _recruiterAuthSubscription;

  GoRouterCombinedRefreshStream(
    CandidateAuthCubit candidateAuthCubit,
    CompanyAuthCubit companyAuthCubit,
    RecruiterAuthCubit recruiterAuthCubit,
  ) {
    _candidateAuthSubscription = candidateAuthCubit.stream.listen(
      (_) => notifyListeners(),
    );
    _companyAuthSubscription = companyAuthCubit.stream.listen(
      (_) => notifyListeners(),
    );
    _recruiterAuthSubscription = recruiterAuthCubit.stream.listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _candidateAuthSubscription.cancel();
    _companyAuthSubscription.cancel();
    _recruiterAuthSubscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static const String _authBootstrapPath = '/_auth-bootstrap';

  AppRouter({required GoRouterCombinedRefreshStream routerRefreshStream}) {
    _router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: routerRefreshStream,
      redirect: _redirectLogic,
      routes: [
        GoRoute(
          path: _authBootstrapPath,
          name: 'auth-bootstrap',
          builder: (context, state) => const _AuthBootstrapScreen(),
        ),
        GoRoute(
          path: '/',
          name: 'landing',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/job-offer',
          name: 'job-offers',
          builder: (context, state) {
            final cubit = JobOffersCubit(
              context.read<JobOfferRepository>(),
              profileRepository: context.read<ProfileRepository>(),
            );
            return BlocProvider(
              create: (_) => cubit,
              child: JobOfferListScreen(cubit: cubit),
            );
          },
        ),
        GoRoute(
          path: '/job-offer/:id',
          name: 'job-offer-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final sourceChannel = state.uri.queryParameters['source'];
            final candidateUid = context
                .read<CandidateAuthCubit>()
                .state
                .candidate
                ?.uid;

            final cubit = JobOfferDetailCubit(
              context.read<JobOfferRepository>(),
              context.read<ApplicationService>(),
              curriculumRepository: context.read<CurriculumRepository>(),
              aiRepository: context.read<AiRepository>(),
              profileRepository: context.read<ProfileRepository>(),
              sourceChannel: sourceChannel,
            )..start(id, candidateUid: candidateUid);

            return BlocProvider(
              create: (_) => cubit,
              child: JobOfferDetailScreen(offerId: id, cubit: cubit),
            );
          },
        ),
        GoRoute(
          path: '/CandidateDashboard',
          name: 'candidate-dashboard-legacy',
          builder: (context, state) {
            final uid =
                context.read<CandidateAuthCubit>().state.candidate?.uid ?? '';
            final applicationsCubit = MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: context.read<FirebaseAuth>(),
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: context.read<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: context.read<CvAnalysisService>(),
            );

            final calendarCubit = CalendarCubit(
              context.read<CalendarRepository>(),
            )..loadMonth(DateTime.now());

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
                BlocProvider(create: (_) => calendarCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 0,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                calendarCubit: calendarCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/candidate/:uid/dashboard',
          name: 'candidate-dashboard',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final applicationsCubit = MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: context.read<FirebaseAuth>(),
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: context.read<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: context.read<CvAnalysisService>(),
            );

            final calendarCubit = CalendarCubit(
              context.read<CalendarRepository>(),
            )..loadMonth(DateTime.now());

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
                BlocProvider(create: (_) => calendarCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 0,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                calendarCubit: calendarCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/candidate/:uid/applications',
          name: 'candidate-applications',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final applicationsCubit = MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: context.read<FirebaseAuth>(),
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: context.read<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: context.read<CvAnalysisService>(),
            );

            final calendarCubit = CalendarCubit(
              context.read<CalendarRepository>(),
            )..loadMonth(DateTime.now());

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
                BlocProvider(create: (_) => calendarCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 1,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                calendarCubit: calendarCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/candidate/:uid/interviews',
          name: 'candidate-interviews',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final applicationsCubit = MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: context.read<FirebaseAuth>(),
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: context.read<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: context.read<CvAnalysisService>(),
            );

            final calendarCubit = CalendarCubit(
              context.read<CalendarRepository>(),
            )..loadMonth(DateTime.now());

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
                BlocProvider(create: (_) => calendarCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 2,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                calendarCubit: calendarCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/candidate/:uid/cv',
          name: 'candidate-cv',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final applicationsCubit = MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: context.read<FirebaseAuth>(),
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: context.read<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: context.read<CvAnalysisService>(),
            );

            final calendarCubit = CalendarCubit(
              context.read<CalendarRepository>(),
            )..loadMonth(DateTime.now());

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
                BlocProvider(create: (_) => calendarCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 3,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                calendarCubit: calendarCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/candidate/:uid/cover-letter',
          name: 'candidate-cover-letter',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final applicationsCubit = MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: context.read<FirebaseAuth>(),
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: context.read<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: context.read<CvAnalysisService>(),
            );

            final calendarCubit = CalendarCubit(
              context.read<CalendarRepository>(),
            )..loadMonth(DateTime.now());

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
                BlocProvider(create: (_) => calendarCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 4,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                calendarCubit: calendarCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/candidate/:uid/video-cv',
          name: 'candidate-video-cv',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final applicationsCubit = MyApplicationsCubit(
              applicationService: context.read<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: context.read<FirebaseAuth>(),
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: context.read<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: context.read<CvAnalysisService>(),
            );

            final calendarCubit = CalendarCubit(
              context.read<CalendarRepository>(),
            )..loadMonth(DateTime.now());

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
                BlocProvider(create: (_) => calendarCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 5,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                calendarCubit: calendarCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/candidate/:uid/privacy',
          name: 'candidate-privacy-portal',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final cubit = DataRequestsCubit(
              repository: context.read<DataRequestRepository>(),
            );
            return BlocProvider(
              create: (_) => cubit,
              child: CandidatePrivacyPortalScreen(candidateUid: uid),
            );
          },
        ),
        GoRoute(
          path: '/DashboardCompany',
          name: 'company-dashboard-legacy',
          builder: (context, state) {
            final uid =
                context.read<CompanyAuthCubit>().state.company?.uid ?? '';
            return _buildCompanyDashboardRoute(
              context: context,
              uid: uid,
              initialIndex: 0,
            );
          },
        ),
        GoRoute(
          path: '/company/:uid/dashboard',
          name: 'company-dashboard',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return _buildCompanyDashboardRoute(
              context: context,
              uid: uid,
              initialIndex: 0,
            );
          },
        ),
        GoRoute(
          path: '/company/:uid/publish-offer',
          name: 'company-publish-offer',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return _buildCompanyDashboardRoute(
              context: context,
              uid: uid,
              initialIndex: 1,
            );
          },
        ),
        GoRoute(
          path: '/company/:uid/offers',
          name: 'company-offers',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return _buildCompanyDashboardRoute(
              context: context,
              uid: uid,
              initialIndex: 2,
            );
          },
        ),
        GoRoute(
          path: '/company/:uid/candidates',
          name: 'company-candidates',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return _buildCompanyDashboardRoute(
              context: context,
              uid: uid,
              initialIndex: 3,
            );
          },
        ),
        GoRoute(
          path: '/company/:uid/interviews',
          name: 'company-interviews',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return _buildCompanyDashboardRoute(
              context: context,
              uid: uid,
              initialIndex: 4,
            );
          },
        ),
        GoRoute(
          path: '/company/profile',
          name: 'company-profile',
          builder: (context, state) {
            final cubit = CompanyProfileFormCubit(
              profileRepository: context.read<ProfileRepository>(),
              companyAuthCubit: context.read<CompanyAuthCubit>(),
            );
            return BlocProvider(
              create: (_) => cubit,
              child: CompanyProfileScreen(cubit: cubit),
            );
          },
        ),
        GoRoute(
          path: '/company/:uid/consents',
          name: 'company-consents',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return ConsentManagementScreen(companyId: uid);
          },
        ),
        GoRoute(
          path: '/company/:uid/analytics',
          name: 'company-analytics',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final cubit = AnalyticsDashboardCubit(
              repository: context.read<AnalyticsRepository>(),
            );
            return BlocProvider(
              create: (_) => cubit,
              child: AnalyticsDashboardScreen(companyId: uid),
            );
          },
        ),

        // ... (existing imports)
        GoRoute(
          path: '/company/offers/:offerId/applicants/:candidateUid/cv',
          name: 'company-applicant-cv',
          builder: (context, state) {
            final uid = state.pathParameters['candidateUid'] ?? '';
            final offerId = state.pathParameters['offerId'] ?? '';

            final cubit = ApplicantCurriculumCubit(
              profileRepository: context.read<ProfileRepository>(),
              curriculumRepository: context.read<CurriculumRepository>(),
              jobOfferRepository: context.read<JobOfferRepository>(),
              aiRepository: context.read<AiRepository>(),
              curriculumPdfService: CurriculumPdfService(),
              curriculumShareService: CurriculumShareService(),
            )..start(candidateUid: uid, offerId: offerId);

            return BlocProvider(
              create: (_) => cubit,
              child: ApplicantCurriculumScreen(
                cubit: cubit,
                candidateUid: uid,
                offerId: offerId,
              ),
            );
          },
        ),
        GoRoute(
          path: '/CandidateLogin',
          name: 'candidate-login',
          builder: (context, state) => const CandidateLoginScreen(),
        ),
        GoRoute(
          path: '/candidateregister',
          name: 'candidate-register',
          builder: (context, state) => const CandidateRegisterScreen(),
        ),
        GoRoute(
          path: '/CompanyLogin',
          name: 'company-login',
          builder: (context, state) => const CompanyLoginScreen(),
        ),
        GoRoute(
          path: '/companyregister',
          name: 'company-register',
          builder: (context, state) => const CompanyRegisterScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        // shell-ex-001 (Fase 6.5): approved exception for immersive interview chat.
        // Source of truth: docs/fase_6_5_registro_excepciones_shell_core.md
        GoRoute(
          path: '/interviews/:id',
          name: 'interview-chat',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final cubit =
                InterviewSessionCubit(
                    repository: context.read<InterviewRepository>(),
                    interviewId: id,
                  )
                  ..start()
                  ..markAsSeen();

            // Wrap in BlocProvider to ensure it gets closed when the route is popped
            return BlocProvider(
              create: (_) => cubit,
              child: InterviewChatPage(cubit: cubit),
            );
          },
        ),
        // ─── Fase 0 RBAC: Recruiter routes ───
        GoRoute(
          path: '/recruiter-login',
          name: 'recruiter-login',
          builder: (context, state) => const RecruiterLoginScreen(),
        ),
        GoRoute(
          path: '/recruiter-register',
          name: 'recruiter-register',
          builder: (context, state) => const RecruiterRegisterInfoScreen(),
        ),
        GoRoute(
          path: '/recruiter/:uid/dashboard',
          name: 'recruiter-dashboard',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            return RecruiterDashboardScreen(recruiterUid: uid);
          },
        ),
      ],
    );
  }

  late final GoRouter _router;

  GoRouter get router => _router;

  Widget _buildCompanyDashboardRoute({
    required BuildContext context,
    required String uid,
    required int initialIndex,
  }) {
    final companyJobOffersCubit = CompanyJobOffersCubit(
      context.read<JobOfferRepository>(),
    );

    final jobOfferFormCubit = JobOfferFormCubit(
      context.read<JobOfferRepository>(),
      context.read<AiService>(),
    );

    final offerApplicantsCubit = OfferApplicantsCubit(
      context.read<ApplicantsRepository>(),
    );

    final companyDashboardCubit = CompanyDashboardCubit(
      companyJobOffersCubit: companyJobOffersCubit,
      companyUid: uid,
      initialIndex: initialIndex,
    );

    final companyOfferCreationCubit = CompanyOfferCreationCubit(
      aiRepository: context.read<AiRepository>(),
    );

    final interviewListCubit = InterviewListCubit(
      repository: context.read<InterviewRepository>(),
      uid: uid,
    )..start();

    final pipelineTemplateCubit = PipelineTemplateCubit(
      pipelineRepository: context.read<PipelineRepository>(),
    )..loadPipelines(uid);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => companyJobOffersCubit),
        BlocProvider(create: (_) => jobOfferFormCubit),
        BlocProvider(create: (_) => offerApplicantsCubit),
        BlocProvider(create: (_) => companyDashboardCubit),
        BlocProvider(create: (_) => companyOfferCreationCubit),
        BlocProvider(create: (_) => interviewListCubit),
        BlocProvider(create: (_) => pipelineTemplateCubit),
      ],
      child: CompanyDashboardScreen(
        dashboardCubit: companyDashboardCubit,
        offerCreationCubit: companyOfferCreationCubit,
        interviewsCubit: interviewListCubit,
      ),
    );
  }

  static const Set<String> _companyDashboardRouteSuffixes = {
    'dashboard',
    'publish-offer',
    'offers',
    'candidates',
    'interviews',
  };

  String _companyDashboardHomePath(String companyUid) {
    final uid = companyUid.trim();
    if (uid.isEmpty) return '/DashboardCompany';
    return '/company/$uid/dashboard';
  }

  String? _companyDashboardCanonicalPath({
    required String location,
    required String companyUid,
  }) {
    final uid = companyUid.trim();
    if (uid.isEmpty) return null;

    final pathSegments = Uri.parse(location).pathSegments;
    if (pathSegments.length != 3) return null;
    if (pathSegments.first != 'company') return null;

    final suffix = pathSegments[2];
    if (!_companyDashboardRouteSuffixes.contains(suffix)) return null;
    return '/company/$uid/$suffix';
  }

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final candidateAuthState = context.read<CandidateAuthCubit>().state;
    final companyAuthState = context.read<CompanyAuthCubit>().state;
    final recruiterAuthState = context.read<RecruiterAuthCubit>().state;
    final candidateUid = candidateAuthState.candidate?.uid ?? '';
    final companyUid = companyAuthState.company?.uid ?? '';
    final recruiterUid = recruiterAuthState.recruiter?.uid ?? '';

    // Determine the active auth state based on who is authenticated
    final authState = candidateAuthState.isAuthenticated
        ? candidateAuthState
        : companyAuthState;

    final location = state.matchedLocation;
    final fullLocation = state.uri.toString();
    final uriPath = state.uri.path;
    final bool loggingInCandidate =
        location == '/CandidateLogin' || location == '/candidateregister';
    final bool loggingInCompany =
        location == '/CompanyLogin' || location == '/companyregister';
    final bool onboardingRoute = location == '/onboarding';
    final bool authBootstrapRoute = location == _authBootstrapPath;
    final bool companyArea = location.startsWith('/company/');
    final bool candidateArea = location.startsWith('/candidate/');
    final bool recruiterArea =
        location.startsWith('/recruiter/') ||
        location == '/recruiter-login' ||
        location == '/recruiter-register';
    final companyDashboardCanonicalPath = _companyDashboardCanonicalPath(
      location: uriPath,
      companyUid: companyUid,
    );
    final routeUid = state.pathParameters['uid'];
    final bool hasAuthenticatedSession =
        candidateAuthState.isAuthenticated ||
        companyAuthState.isAuthenticated ||
        recruiterAuthState.isAuthenticated;
    final bool pendingSessionRestore =
        !hasAuthenticatedSession &&
        (candidateAuthState.status == AuthStatus.unknown ||
            companyAuthState.status == AuthStatus.unknown ||
            recruiterAuthState.status == AuthStatus.unknown);

    if (!FeatureFlags.recruiterModule && recruiterArea) {
      return '/';
    }

    // Si ya está autenticado como reclutador, evita volver a login/register.
    if ((location == '/recruiter-login' || location == '/recruiter-register') &&
        recruiterAuthState.isAuthenticated) {
      return '/recruiter/$recruiterUid/dashboard';
    }

    // ─ Recruiter area: requires recruiter authentication ─
    if (recruiterArea && location.startsWith('/recruiter/')) {
      if (!recruiterAuthState.isAuthenticated) return '/recruiter-login';
      if (routeUid != null && routeUid.isNotEmpty && routeUid != recruiterUid) {
        return '/recruiter/$recruiterUid/dashboard';
      }
      return null;
    }

    if (pendingSessionRestore) {
      if (authBootstrapRoute) return null;
      final bootstrapUri = Uri(
        path: _authBootstrapPath,
        queryParameters: {'from': fullLocation},
      );
      return bootstrapUri.toString();
    }

    if (authBootstrapRoute) {
      final from = state.uri.queryParameters['from'];
      final hasValidFrom =
          from != null &&
          from.isNotEmpty &&
          !from.startsWith(_authBootstrapPath);
      if (hasValidFrom) {
        return from;
      }
      if (recruiterAuthState.isAuthenticated) {
        return '/recruiter/$recruiterUid/dashboard';
      }
      if (!authState.isAuthenticated) return '/';
      if (authState.needsOnboarding) return '/onboarding';
      if (authState.isCandidate) {
        if (candidateUid.isNotEmpty) {
          return '/candidate/$candidateUid/dashboard';
        }
        return '/CandidateDashboard';
      }
      return _companyDashboardHomePath(companyUid);
    }

    final recruiterOnlySession =
        recruiterAuthState.isAuthenticated &&
        !candidateAuthState.isAuthenticated &&
        !companyAuthState.isAuthenticated;
    final recruiterCompanyRouteAllowed =
        recruiterOnlySession &&
        companyArea &&
        routeUid != null &&
        routeUid.isNotEmpty &&
        routeUid == recruiterAuthState.recruiter?.companyId &&
        (uriPath.endsWith('/analytics') || uriPath.endsWith('/consents'));

    if (recruiterOnlySession) {
      if (recruiterArea || recruiterCompanyRouteAllowed) return null;
      return '/recruiter/$recruiterUid/dashboard';
    }

    if (!authState.isAuthenticated) {
      if (onboardingRoute) return '/';
      if (location == '/CandidateDashboard') return '/CandidateLogin';
      if (candidateArea) return '/CandidateLogin';
      if (location == '/DashboardCompany') return '/CompanyLogin';
      if (companyArea) return '/CompanyLogin';
      return null;
    }

    if (authState.needsOnboarding && !onboardingRoute) {
      return '/onboarding';
    }

    if (!authState.needsOnboarding && onboardingRoute) {
      return authState.isCandidate
          ? '/candidate/$candidateUid/dashboard'
          : _companyDashboardHomePath(companyUid);
    }

    if (authState.isCandidate && location == '/DashboardCompany') {
      return '/candidate/$candidateUid/dashboard';
    }

    if (authState.isCompany && location == '/CandidateDashboard') {
      return _companyDashboardHomePath(companyUid);
    }

    if (authState.isCandidate && companyArea) {
      return '/candidate/$candidateUid/dashboard';
    }

    if (authState.isCompany && location == '/DashboardCompany') {
      return _companyDashboardHomePath(companyUid);
    }

    if (authState.isCompany &&
        companyArea &&
        routeUid != null &&
        routeUid.isNotEmpty &&
        routeUid != companyUid) {
      return _companyDashboardHomePath(companyUid);
    }

    if (authState.isCompany &&
        companyDashboardCanonicalPath != null &&
        companyDashboardCanonicalPath != uriPath) {
      return companyDashboardCanonicalPath;
    }

    if (authState.isCandidate && (loggingInCandidate || loggingInCompany)) {
      return '/candidate/$candidateUid/dashboard';
    }

    if (authState.isCompany && (loggingInCandidate || loggingInCompany)) {
      return _companyDashboardHomePath(companyUid);
    }

    if (authState.isCandidate && location == '/CandidateDashboard') {
      return '/candidate/$candidateUid/dashboard';
    }

    if (authState.isCandidate &&
        candidateArea &&
        routeUid != null &&
        routeUid.isNotEmpty &&
        routeUid != candidateUid) {
      return '/candidate/$candidateUid/dashboard';
    }

    return null;
  }
}

class _AuthBootstrapScreen extends StatelessWidget {
  const _AuthBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
