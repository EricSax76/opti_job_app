import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:infojobs_flutter_app/features/auth/candidate_login_screen.dart';
import 'package:infojobs_flutter_app/features/auth/candidate_register_screen.dart';
import 'package:infojobs_flutter_app/features/auth/company_login_screen.dart';
import 'package:infojobs_flutter_app/features/auth/company_register_screen.dart';
import 'package:infojobs_flutter_app/features/dashboards/candidate_dashboard_screen.dart';
import 'package:infojobs_flutter_app/features/dashboards/company_dashboard_screen.dart';
import 'package:infojobs_flutter_app/features/job_offers/job_offer_detail_screen.dart';
import 'package:infojobs_flutter_app/features/job_offers/job_offer_list_screen.dart';
import 'package:infojobs_flutter_app/features/landing/landing_screen.dart';
import 'package:infojobs_flutter_app/providers/auth_providers.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    refreshListenable: authState,
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
          return JobOfferDetailScreen(offerId: id);
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
        builder: (context, state) => const CompanyDashboardScreen(),
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
    ],
  );
});
