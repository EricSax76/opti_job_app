import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/recruiters/ui/pages/recruiter_dashboard_screen.dart';
import 'package:opti_job_app/modules/recruiters/ui/pages/recruiter_login_screen.dart';
import 'package:opti_job_app/modules/recruiters/ui/pages/recruiter_register_screen.dart';
import 'package:opti_job_app/modules/recruiters/ui/pages/recruiter_team_management_screen.dart';

List<RouteBase> buildRecruiterRoutes() {
  return [
    // Fase 0 RBAC: Recruiter routes.
    GoRoute(
      path: '/recruiter-login',
      name: 'recruiter-login',
      builder: (context, state) => const RecruiterLoginScreen(),
    ),
    GoRoute(
      path: '/recruiter-register',
      name: 'recruiter-register',
      builder: (context, state) => const RecruiterRegisterScreen(),
    ),
    GoRoute(
      path: '/recruiter/:uid/dashboard',
      name: 'recruiter-dashboard',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return RecruiterDashboardScreen(recruiterUid: uid);
      },
    ),
    GoRoute(
      path: '/recruiter/:uid/team',
      name: 'recruiter-team',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return RecruiterTeamManagementScreen(recruiterUid: uid);
      },
    ),
  ];
}
