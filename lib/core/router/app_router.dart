import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/ui/pages/candidate_login_screen.dart';
import 'package:opti_job_app/auth/ui/pages/candidate_register_screen.dart';
import 'package:opti_job_app/auth/ui/pages/company_login_screen.dart';
import 'package:opti_job_app/auth/ui/pages/company_register_screen.dart';
import 'package:opti_job_app/home/pages/onboarding_screen.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_dashboard_screen.dart';
import 'package:opti_job_app/home/pages/landing_screen.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_list_screen.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_detail_screen.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
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
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/interviews/ui/pages/interview_chat_page.dart';

import 'package:get_it/get_it.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';

/// Listens to a stream and notifies GoRouter when auth state changes.
class GoRouterCombinedRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _candidateAuthSubscription;
  late final StreamSubscription<dynamic> _companyAuthSubscription;

  GoRouterCombinedRefreshStream(
    CandidateAuthCubit candidateAuthCubit,
    CompanyAuthCubit companyAuthCubit,
  ) {
    _candidateAuthSubscription = candidateAuthCubit.stream.listen(
      (_) => notifyListeners(),
    );
    _companyAuthSubscription = companyAuthCubit.stream.listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _candidateAuthSubscription.cancel();
    _companyAuthSubscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  AppRouter({required GoRouterCombinedRefreshStream routerRefreshStream}) {
    _router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: routerRefreshStream,
      redirect: _redirectLogic,
      routes: [
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
            final candidateUid = context
                .read<CandidateAuthCubit>()
                .state
                .candidate
                ?.uid;

            final cubit = JobOfferDetailCubit(
              context.read<JobOfferRepository>(),
              GetIt.I<ApplicationService>(),
              curriculumRepository: context.read<CurriculumRepository>(),
              aiRepository: GetIt.I<AiRepository>(),
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
              applicationService: GetIt.I<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: FirebaseAuth.instance,
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: CvAnalysisService(),
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 0,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
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
              applicationService: GetIt.I<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: FirebaseAuth.instance,
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: CvAnalysisService(),
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 0,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
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
              applicationService: GetIt.I<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: FirebaseAuth.instance,
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: CvAnalysisService(),
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 1,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
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
              applicationService: GetIt.I<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: FirebaseAuth.instance,
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: CvAnalysisService(),
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 2,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
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
              applicationService: GetIt.I<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: FirebaseAuth.instance,
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: CvAnalysisService(),
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 3,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
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
              applicationService: GetIt.I<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: FirebaseAuth.instance,
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: CvAnalysisService(),
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 4,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
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
              applicationService: GetIt.I<ApplicationService>(),
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
              firebaseAuth: FirebaseAuth.instance,
            )..start();

            final interviewsCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: uid,
            )..start();

            final curriculumCubit = context.read<CurriculumCubit>();
            final curriculumFormCubit = CurriculumFormCubit(
              curriculumCubit: curriculumCubit,
              analysisService: CvAnalysisService(),
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => applicationsCubit),
                BlocProvider(create: (_) => interviewsCubit),
                BlocProvider(create: (_) => curriculumFormCubit),
              ],
              child: CandidateDashboardScreen(
                uid: uid,
                initialIndex: 5,
                applicationsCubit: applicationsCubit,
                interviewsCubit: interviewsCubit,
                curriculumFormCubit: curriculumFormCubit,
                profileCubit: context.read<ProfileCubit>(),
              ),
            );
          },
        ),
        GoRoute(
          path: '/DashboardCompany',
          name: 'company-dashboard',
          builder: (context, state) {
            final companyJobOffersCubit = CompanyJobOffersCubit(
              context.read<JobOfferRepository>(),
            );

            final jobOfferFormCubit = JobOfferFormCubit(
              context.read<JobOfferRepository>(),
            );

            final offerApplicantsCubit = OfferApplicantsCubit(
              GetIt.I<ApplicantsRepository>(),
            );

            final companyDashboardCubit = CompanyDashboardCubit(
              companyJobOffersCubit: companyJobOffersCubit,
            );

            final companyOfferCreationCubit = CompanyOfferCreationCubit(
              aiRepository: GetIt.I<AiRepository>(),
            );

            // We need companyUid for InterviewListCubit.
            // We can try to get it from auth state, but it might be null if not fully initialized?
            // However, the redirect logic ensures we are authenticated.
            final companyUid =
                context.read<CompanyAuthCubit>().state.company?.uid ?? '';

            final interviewListCubit = InterviewListCubit(
              repository: GetIt.I<InterviewRepository>(),
              uid: companyUid,
            );

            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => companyJobOffersCubit),
                BlocProvider(create: (_) => jobOfferFormCubit),
                BlocProvider(create: (_) => offerApplicantsCubit),
                BlocProvider(create: (_) => companyDashboardCubit),
                BlocProvider(create: (_) => companyOfferCreationCubit),
                BlocProvider(create: (_) => interviewListCubit),
              ],
              child: CompanyDashboardScreen(
                dashboardCubit: companyDashboardCubit,
                offerCreationCubit: companyOfferCreationCubit,
                interviewsCubit: interviewListCubit,
              ),
            );
          },
        ),
        GoRoute(
          path: '/company/profile',
          name: 'company-profile',
          builder: (context, state) {
            final cubit = CompanyProfileFormCubit(
              profileRepository: GetIt.I<ProfileRepository>(),
              companyAuthCubit: context.read<CompanyAuthCubit>(),
            );
            return BlocProvider(
              create: (_) => cubit,
              child: CompanyProfileScreen(cubit: cubit),
            );
          },
        ),

        // ... (existing imports)
        GoRoute(
          path: '/company/offers/:offerId/applicants/:uid/cv',
          name: 'company-applicant-cv',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final offerId = state.pathParameters['offerId'] ?? '';

            final cubit = ApplicantCurriculumCubit(
              profileRepository: GetIt.I<ProfileRepository>(),
              curriculumRepository: GetIt.I<CurriculumRepository>(),
              jobOfferRepository: GetIt.I<JobOfferRepository>(),
              aiRepository: GetIt.I<AiRepository>(),
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
        GoRoute(
          path: '/interviews/:id',
          name: 'interview-chat',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final cubit =
                InterviewSessionCubit(
                    repository: GetIt.I<InterviewRepository>(),
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
      ],
    );
  }

  late final GoRouter _router;

  GoRouter get router => _router;

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final candidateAuthState = context.read<CandidateAuthCubit>().state;
    final companyAuthState = context.read<CompanyAuthCubit>().state;
    final candidateUid = candidateAuthState.candidate?.uid ?? '';

    // Determine the active auth state based on who is authenticated
    final authState = candidateAuthState.isAuthenticated
        ? candidateAuthState
        : companyAuthState;

    final location = state.matchedLocation;
    final bool loggingInCandidate =
        location == '/CandidateLogin' || location == '/candidateregister';
    final bool loggingInCompany =
        location == '/CompanyLogin' || location == '/companyregister';
    final bool onboardingRoute = location == '/onboarding';
    final bool companyArea = location.startsWith('/company/');
    final bool candidateArea = location.startsWith('/candidate/');
    final routeUid = state.pathParameters['uid'];

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
          : '/DashboardCompany';
    }

    if (authState.isCandidate && location == '/DashboardCompany') {
      return '/candidate/$candidateUid/dashboard';
    }

    if (authState.isCompany && location == '/CandidateDashboard') {
      return '/DashboardCompany';
    }

    if (authState.isCandidate && companyArea) {
      return '/candidate/$candidateUid/dashboard';
    }

    if (authState.isCandidate && (loggingInCandidate || loggingInCompany)) {
      return '/candidate/$candidateUid/dashboard';
    }

    if (authState.isCompany && (loggingInCandidate || loggingInCompany)) {
      return '/DashboardCompany';
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
