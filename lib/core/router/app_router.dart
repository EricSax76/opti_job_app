import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/router/auth_redirect.dart';
import 'package:opti_job_app/core/router/routes/candidate_routes.dart';
import 'package:opti_job_app/core/router/routes/company_routes.dart';
import 'package:opti_job_app/core/router/routes/public_routes.dart';
import 'package:opti_job_app/core/router/routes/recruiter_routes.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';

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
      redirect: (context, state) => appAuthRedirect(
        context: context,
        state: state,
        authBootstrapPath: _authBootstrapPath,
      ),
      routes: [
        ...buildPublicRoutes(authBootstrapPath: _authBootstrapPath),
        ...buildCandidateRoutes(),
        ...buildCompanyRoutes(),
        ...buildRecruiterRoutes(),
      ],
    );
  }

  late final GoRouter _router;

  GoRouter get router => _router;
}
