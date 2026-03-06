import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';

const Set<String> _companyDashboardRouteSuffixes = {
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

String? appAuthRedirect({
  required BuildContext context,
  required GoRouterState state,
  required String authBootstrapPath,
}) {
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
  final bool authBootstrapRoute = location == authBootstrapPath;
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

  // Recruiter area: requires recruiter authentication.
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
      path: authBootstrapPath,
      queryParameters: {'from': fullLocation},
    );
    return bootstrapUri.toString();
  }

  if (authBootstrapRoute) {
    final from = state.uri.queryParameters['from'];
    final hasValidFrom =
        from != null && from.isNotEmpty && !from.startsWith(authBootstrapPath);
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
