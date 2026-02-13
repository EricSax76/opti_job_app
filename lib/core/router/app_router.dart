import 'dart:async';

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
import 'package:opti_job_app/modules/companies/ui/pages/company_dashboard_screen.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_profile_screen.dart';
import 'package:opti_job_app/modules/applicants/ui/pages/applicant_curriculum_screen.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_detail_screen.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_list_screen.dart';
import 'package:opti_job_app/home/pages/landing_screen.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/pages/interview_chat_page.dart';

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
          builder: (context, state) => const JobOfferListScreen(),
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
            return BlocProvider(
              create: (context) => JobOfferDetailCubit(
                context.read<JobOfferRepository>(),
                context.read<ApplicationService>(),
              )..loadOffer(id, candidateUid: candidateUid),
              child: JobOfferDetailScreen(offerId: id),
            );
          },
        ),
        GoRoute(
          path: '/CandidateDashboard',
          name: 'candidate-dashboard-legacy',
          builder: (context, state) {
            final uid =
                context.read<CandidateAuthCubit>().state.candidate?.uid ?? '';
            return CandidateDashboardScreen(uid: uid, initialIndex: 0);
          },
        ),
        GoRoute(
          path: '/candidate/:uid/dashboard',
          name: 'candidate-dashboard',
          builder: (context, state) => CandidateDashboardScreen(
            uid: state.pathParameters['uid'] ?? '',
            initialIndex: 0,
          ),
        ),
        GoRoute(
          path: '/candidate/:uid/applications',
          name: 'candidate-applications',
          builder: (context, state) => CandidateDashboardScreen(
            uid: state.pathParameters['uid'] ?? '',
            initialIndex: 1,
          ),
        ),
        GoRoute(
          path: '/candidate/:uid/interviews',
          name: 'candidate-interviews',
          builder: (context, state) => CandidateDashboardScreen(
            uid: state.pathParameters['uid'] ?? '',
            initialIndex: 2,
          ),
        ),
        GoRoute(
          path: '/candidate/:uid/cv',
          name: 'candidate-cv',
          builder: (context, state) => CandidateDashboardScreen(
            uid: state.pathParameters['uid'] ?? '',
            initialIndex: 3,
          ),
        ),
        GoRoute(
          path: '/candidate/:uid/cover-letter',
          name: 'candidate-cover-letter',
          builder: (context, state) => CandidateDashboardScreen(
            uid: state.pathParameters['uid'] ?? '',
            initialIndex: 4,
          ),
        ),
        GoRoute(
          path: '/candidate/:uid/video-cv',
          name: 'candidate-video-cv',
          builder: (context, state) => CandidateDashboardScreen(
            uid: state.pathParameters['uid'] ?? '',
            initialIndex: 5,
          ),
        ),
        GoRoute(
          path: '/DashboardCompany',
          name: 'company-dashboard',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    JobOfferFormCubit(context.read<JobOfferRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    CompanyJobOffersCubit(context.read<JobOfferRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    OfferApplicantsCubit(context.read<ApplicantsRepository>()),
              ),
            ],
            child: const CompanyDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/company/profile',
          name: 'company-profile',
          builder: (context, state) => const CompanyProfileScreen(),
        ),
        GoRoute(
          path: '/company/offers/:offerId/applicants/:uid/cv',
          name: 'company-applicant-cv',
          builder: (context, state) {
            final uid = state.pathParameters['uid'] ?? '';
            final offerId = state.pathParameters['offerId'] ?? '';
            return ApplicantCurriculumScreen(
              candidateUid: uid,
              offerId: offerId,
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
            return InterviewChatPage(interviewId: id);
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
    final bool companyArea = location.startsWith('/company');
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
