import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubit/ui/candidate_login_screen.dart';
import 'package:opti_job_app/auth/cubit/ui/candidate_register_screen.dart';
import 'package:opti_job_app/auth/cubit/ui/company_login_screen.dart';
import 'package:opti_job_app/auth/cubit/ui/company_register_screen.dart';
import 'package:opti_job_app/home/onboarding_screen.dart';
import 'package:opti_job_app/auth/cubit/auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/candidate_dashboard_screen.dart';
import 'package:opti_job_app/modules/companies/ui/company_dashboard_screen.dart';
import 'package:opti_job_app/data/services/application_service.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/ui/job_offer_detail_screen.dart';
import 'package:opti_job_app/modules/job_offers/ui/job_offer_list_screen.dart';
import 'package:opti_job_app/home/landing_screen.dart';
import 'package:opti_job_app/data/repositories/job_offer_repository.dart';

class AppRouter {
  AppRouter({required AuthCubit authCubit}) : _authCubit = authCubit {
    _router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(_authCubit.stream),
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
            return BlocProvider(
              create: (context) => JobOfferDetailCubit(
                context.read<JobOfferRepository>(),
                context.read<ApplicationService>(),
              )..loadOffer(id),
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
          builder: (context, state) => BlocProvider(
            create: (context) =>
                JobOfferFormCubit(context.read<JobOfferRepository>()),
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

  final AuthCubit _authCubit;
  late final GoRouter _router;

  GoRouter get router => _router;

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final authState = _authCubit.state;
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

/// Listens to a stream and notifies GoRouter when auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
