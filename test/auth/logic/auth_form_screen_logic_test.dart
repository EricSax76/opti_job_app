import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

void main() {
  Candidate candidate({String uid = 'candidate-1'}) {
    return Candidate(
      id: 1,
      name: 'Ana',
      lastName: 'Perez',
      email: 'ana@example.com',
      uid: uid,
      role: 'candidate',
    );
  }

  Company company({String uid = 'company-1'}) {
    return Company(id: 1, name: 'Acme', email: 'acme@example.com', uid: uid);
  }

  group('AuthFormScreenLogic', () {
    test('buildViewModel maps authenticating status', () {
      expect(
        AuthFormScreenLogic.buildViewModel(AuthStatus.authenticating).isLoading,
        isTrue,
      );
      expect(
        AuthFormScreenLogic.buildViewModel(AuthStatus.authenticated).isLoading,
        isFalse,
      );
    });

    test('resolveErrorMessage trims and ignores blank values', () {
      expect(AuthFormScreenLogic.resolveErrorMessage('  Error  '), 'Error');
      expect(AuthFormScreenLogic.resolveErrorMessage('  '), isNull);
      expect(AuthFormScreenLogic.resolveErrorMessage(null), isNull);
    });

    test('candidateLoginNavigation resolves dashboard route with uid', () {
      final state = CandidateAuthState(
        status: AuthStatus.authenticated,
        candidate: candidate(uid: 'uid-123'),
      );

      expect(
        AuthFormScreenLogic.candidateLoginNavigation(state),
        '/candidate/uid-123/dashboard',
      );
    });

    test('candidateLoginNavigation falls back when uid is blank', () {
      final state = CandidateAuthState(
        status: AuthStatus.authenticated,
        candidate: candidate(uid: '   '),
      );

      expect(
        AuthFormScreenLogic.candidateLoginNavigation(state),
        '/CandidateDashboard',
      );
    });

    test('candidateRegisterNavigation requires onboarding', () {
      final onboardingState = CandidateAuthState(
        status: AuthStatus.authenticated,
        needsOnboarding: true,
      );
      final regularState = CandidateAuthState(
        status: AuthStatus.authenticated,
        needsOnboarding: false,
      );

      expect(
        AuthFormScreenLogic.candidateRegisterNavigation(onboardingState),
        '/onboarding',
      );
      expect(
        AuthFormScreenLogic.candidateRegisterNavigation(regularState),
        isNull,
      );
    });

    test('company login/register navigation rules', () {
      final loginState = CompanyAuthState(
        status: AuthStatus.authenticated,
        company: company(),
      );
      final onboardingState = CompanyAuthState(
        status: AuthStatus.authenticated,
        company: company(),
        needsOnboarding: true,
      );

      expect(
        AuthFormScreenLogic.companyLoginNavigation(loginState),
        '/DashboardCompany',
      );
      expect(
        AuthFormScreenLogic.companyRegisterNavigation(onboardingState),
        '/onboarding',
      );
    });

    test('listen predicates react to meaningful auth changes', () {
      final candidatePrev = CandidateAuthState(
        status: AuthStatus.unauthenticated,
      );
      final candidateNext = CandidateAuthState(
        status: AuthStatus.authenticating,
      );

      final companyPrev = CompanyAuthState(status: AuthStatus.unauthenticated);
      final companyNext = CompanyAuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error',
      );

      expect(
        AuthFormScreenLogic.shouldListenCandidateLogin(
          candidatePrev,
          candidateNext,
        ),
        isTrue,
      );
      expect(
        AuthFormScreenLogic.shouldListenCandidateRegister(
          candidatePrev,
          candidatePrev,
        ),
        isFalse,
      );
      expect(
        AuthFormScreenLogic.shouldListenCompanyLogin(companyPrev, companyNext),
        isTrue,
      );
      expect(
        AuthFormScreenLogic.shouldListenCompanyRegister(
          companyPrev,
          companyPrev,
        ),
        isFalse,
      );
    });
  });
}
