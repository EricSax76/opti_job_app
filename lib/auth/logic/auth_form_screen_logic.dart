import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/ui/models/auth_form_screen_view_model.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_state.dart';

class AuthFormScreenLogic {
  const AuthFormScreenLogic._();

  static AuthFormScreenViewModel buildViewModel(AuthStatus status) {
    return AuthFormScreenViewModel(
      isLoading: status == AuthStatus.authenticating,
    );
  }

  static bool shouldListenCandidateLogin(
    CandidateAuthState previous,
    CandidateAuthState current,
  ) {
    return previous.errorMessage != current.errorMessage ||
        previous.status != current.status ||
        previous.needsOnboarding != current.needsOnboarding;
  }

  static bool shouldListenCandidateRegister(
    CandidateAuthState previous,
    CandidateAuthState current,
  ) {
    return previous.errorMessage != current.errorMessage ||
        previous.status != current.status ||
        previous.needsOnboarding != current.needsOnboarding;
  }

  static bool shouldListenCompanyLogin(
    CompanyAuthState previous,
    CompanyAuthState current,
  ) {
    return previous.errorMessage != current.errorMessage ||
        previous.status != current.status ||
        previous.needsOnboarding != current.needsOnboarding;
  }

  static bool shouldListenCompanyRegister(
    CompanyAuthState previous,
    CompanyAuthState current,
  ) {
    return previous.errorMessage != current.errorMessage ||
        previous.status != current.status ||
        previous.needsOnboarding != current.needsOnboarding;
  }

  static bool shouldListenRecruiterLogin(
    RecruiterAuthState previous,
    RecruiterAuthState current,
  ) {
    return previous.errorMessage != current.errorMessage ||
        previous.status != current.status;
  }

  static String? resolveErrorMessage(String? errorMessage) {
    return _normalizeText(errorMessage);
  }

  static String? candidateLoginNavigation(CandidateAuthState state) {
    final shouldNavigate =
        state.isAuthenticated &&
        state.status == AuthStatus.authenticated &&
        !state.needsOnboarding;
    if (!shouldNavigate) return null;

    final uid = _normalizeText(state.candidate?.uid);
    if (uid != null) return '/candidate/$uid/dashboard';
    return '/CandidateDashboard';
  }

  static String? candidateRegisterNavigation(CandidateAuthState state) {
    if (state.isAuthenticated && state.needsOnboarding) return '/onboarding';
    return null;
  }

  static String? companyLoginNavigation(CompanyAuthState state) {
    final shouldNavigate =
        state.isAuthenticated &&
        state.status == AuthStatus.authenticated &&
        !state.needsOnboarding;
    if (!shouldNavigate) return null;

    final uid = _normalizeText(state.company?.uid);
    if (uid != null) return '/company/$uid/dashboard';
    return '/DashboardCompany';
  }

  static String? companyRegisterNavigation(CompanyAuthState state) {
    if (state.isAuthenticated && state.needsOnboarding) return '/onboarding';
    return null;
  }

  static String? recruiterLoginNavigation(RecruiterAuthState state) {
    final shouldNavigate =
        state.isAuthenticated && state.status == AuthStatus.authenticated;
    if (!shouldNavigate) return null;

    final uid = _normalizeText(state.recruiter?.uid);
    if (uid == null) return null;
    return '/recruiter/$uid/dashboard';
  }

  static String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
