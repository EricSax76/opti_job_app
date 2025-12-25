import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/candidates/ui/pages/candidate_login_screen.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_register_screen.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_login_screen.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_register_screen.dart';
import 'package:opti_job_app/home/pages/onboarding_screen.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_dashboard_screen.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_dashboard_screen.dart';
import 'package:opti_job_app/modules/aplications/models/application_service.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_detail_screen.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_list_screen.dart';
import 'package:opti_job_app/home/pages/landing_screen.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';

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
            final idParam = state.pathParameters['id'] ?? '0';
            final id = int.tryParse(idParam) ?? 0;
            final candidateUid =
                context.read<CandidateAuthCubit>().state.candidate?.uid;
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
          name: 'candidate-dashboard',
          builder: (context, state) => const CandidateDashboardScreen(),
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
                    OfferApplicantsCubit(context.read<ApplicationService>()),
              ),
            ],
            child: const CompanyDashboardScreen(),
          ),
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
      ],
    );
  }

  late final GoRouter _router;

  GoRouter get router => _router;

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final candidateAuthState = context.read<CandidateAuthCubit>().state;
    final companyAuthState = context.read<CompanyAuthCubit>().state;

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

    if (!authState.isAuthenticated) {
      if (onboardingRoute) return '/';
      if (location == '/CandidateDashboard') return '/CandidateLogin';
      if (location == '/DashboardCompany') return '/CompanyLogin';
      return null;
    }

    if (authState.needsOnboarding && !onboardingRoute) {
      return '/onboarding';
    }

    if (!authState.needsOnboarding && onboardingRoute) {
      return authState.isCandidate
          ? '/CandidateDashboard'
          : '/DashboardCompany';
    }

    if (authState.isCandidate && location == '/DashboardCompany') {
      return '/CandidateDashboard';
    }

    if (authState.isCompany && location == '/CandidateDashboard') {
      return '/DashboardCompany';
    }

    if (authState.isCandidate && (loggingInCandidate || loggingInCompany)) {
      return '/CandidateDashboard';
    }

    if (authState.isCompany && (loggingInCandidate || loggingInCompany)) {
      return '/DashboardCompany';
    }

    return null;
  }
}
