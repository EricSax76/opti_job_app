import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/core/config/feature_flags.dart';
import 'package:opti_job_app/core/router/auth_redirect.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_state.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

class _MockCandidateAuthCubit extends Mock implements CandidateAuthCubit {}

class _MockCompanyAuthCubit extends Mock implements CompanyAuthCubit {}

class _MockRecruiterAuthCubit extends Mock implements RecruiterAuthCubit {}

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('appAuthRedirect', () {
    testWidgets('redirects unauthenticated candidate area to candidate login', (
      tester,
    ) async {
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: const CandidateAuthState(
          status: AuthStatus.unauthenticated,
        ),
        companyState: const CompanyAuthState(
          status: AuthStatus.unauthenticated,
        ),
        recruiterState: const RecruiterAuthState(
          status: AuthStatus.unauthenticated,
        ),
        matchedLocation: '/candidate/abc/dashboard',
        uri: Uri.parse('/candidate/abc/dashboard'),
        pathParameters: const {'uid': 'abc'},
      );

      expect(redirect, '/CandidateLogin');
    });

    testWidgets('redirects unauthenticated company area to company login', (
      tester,
    ) async {
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: const CandidateAuthState(
          status: AuthStatus.unauthenticated,
        ),
        companyState: const CompanyAuthState(
          status: AuthStatus.unauthenticated,
        ),
        recruiterState: const RecruiterAuthState(
          status: AuthStatus.unauthenticated,
        ),
        matchedLocation: '/company/acme/dashboard',
        uri: Uri.parse('/company/acme/dashboard'),
        pathParameters: const {'uid': 'acme'},
      );

      expect(redirect, '/CompanyLogin');
    });

    testWidgets(
      'redirects authenticated candidate away from company area to own dashboard',
      (tester) async {
        final redirect = await _evaluateRedirect(
          tester: tester,
          candidateState: CandidateAuthState(
            status: AuthStatus.authenticated,
            candidate: _candidate(uid: 'cand-1'),
          ),
          companyState: const CompanyAuthState(
            status: AuthStatus.unauthenticated,
          ),
          recruiterState: const RecruiterAuthState(
            status: AuthStatus.unauthenticated,
          ),
          matchedLocation: '/company/acme/dashboard',
          uri: Uri.parse('/company/acme/dashboard'),
          pathParameters: const {'uid': 'acme'},
        );

        expect(redirect, '/candidate/cand-1/dashboard');
      },
    );

    testWidgets('redirects authenticated company from candidate legacy route', (
      tester,
    ) async {
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: const CandidateAuthState(
          status: AuthStatus.unauthenticated,
        ),
        companyState: CompanyAuthState(
          status: AuthStatus.authenticated,
          company: _company(uid: 'comp-1'),
        ),
        recruiterState: const RecruiterAuthState(
          status: AuthStatus.unauthenticated,
        ),
        matchedLocation: '/CandidateDashboard',
        uri: Uri.parse('/CandidateDashboard'),
      );

      expect(redirect, '/company/comp-1/dashboard');
    });

    testWidgets('redirects candidate route with mismatched uid to own uid', (
      tester,
    ) async {
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: CandidateAuthState(
          status: AuthStatus.authenticated,
          candidate: _candidate(uid: 'cand-1'),
        ),
        companyState: const CompanyAuthState(
          status: AuthStatus.unauthenticated,
        ),
        recruiterState: const RecruiterAuthState(
          status: AuthStatus.unauthenticated,
        ),
        matchedLocation: '/candidate/other/interviews',
        uri: Uri.parse('/candidate/other/interviews'),
        pathParameters: const {'uid': 'other'},
      );

      expect(redirect, '/candidate/cand-1/dashboard');
    });

    testWidgets('redirects company route with mismatched uid to company home', (
      tester,
    ) async {
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: const CandidateAuthState(
          status: AuthStatus.unauthenticated,
        ),
        companyState: CompanyAuthState(
          status: AuthStatus.authenticated,
          company: _company(uid: 'comp-1'),
        ),
        recruiterState: const RecruiterAuthState(
          status: AuthStatus.unauthenticated,
        ),
        matchedLocation: '/company/other/offers',
        uri: Uri.parse('/company/other/offers'),
        pathParameters: const {'uid': 'other'},
      );

      expect(redirect, '/company/comp-1/dashboard');
    });

    testWidgets(
      'forces onboarding when authenticated candidate still needs it',
      (tester) async {
        final redirect = await _evaluateRedirect(
          tester: tester,
          candidateState: CandidateAuthState(
            status: AuthStatus.authenticated,
            candidate: _candidate(uid: 'cand-1'),
            needsOnboarding: true,
          ),
          companyState: const CompanyAuthState(
            status: AuthStatus.unauthenticated,
          ),
          recruiterState: const RecruiterAuthState(
            status: AuthStatus.unauthenticated,
          ),
          matchedLocation: '/candidate/cand-1/dashboard',
          uri: Uri.parse('/candidate/cand-1/dashboard'),
          pathParameters: const {'uid': 'cand-1'},
        );

        expect(redirect, '/onboarding');
      },
    );

    testWidgets('leaves onboarding to candidate dashboard when completed', (
      tester,
    ) async {
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: CandidateAuthState(
          status: AuthStatus.authenticated,
          candidate: _candidate(uid: 'cand-1'),
          needsOnboarding: false,
        ),
        companyState: const CompanyAuthState(
          status: AuthStatus.unauthenticated,
        ),
        recruiterState: const RecruiterAuthState(
          status: AuthStatus.unauthenticated,
        ),
        matchedLocation: '/onboarding',
        uri: Uri.parse('/onboarding'),
      );

      expect(redirect, '/candidate/cand-1/dashboard');
    });

    testWidgets('uses auth bootstrap while session restore is pending', (
      tester,
    ) async {
      const from = '/candidate/abc/dashboard?tab=cv';
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: const CandidateAuthState(),
        companyState: const CompanyAuthState(),
        recruiterState: const RecruiterAuthState(),
        matchedLocation: '/candidate/abc/dashboard',
        uri: Uri.parse(from),
        pathParameters: const {'uid': 'abc'},
      );

      final expected = Uri(
        path: '/_auth-bootstrap',
        queryParameters: const {'from': from},
      ).toString();
      expect(redirect, expected);
    });

    testWidgets('returns original from query when already in auth bootstrap', (
      tester,
    ) async {
      const from = '/company/comp-1/dashboard';
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: const CandidateAuthState(
          status: AuthStatus.unauthenticated,
        ),
        companyState: const CompanyAuthState(
          status: AuthStatus.unauthenticated,
        ),
        recruiterState: const RecruiterAuthState(
          status: AuthStatus.unauthenticated,
        ),
        matchedLocation: '/_auth-bootstrap',
        uri: Uri.parse('/_auth-bootstrap?from=${Uri.encodeComponent(from)}'),
      );

      expect(redirect, from);
    });

    testWidgets('handles recruiter area based on feature flag', (tester) async {
      final redirect = await _evaluateRedirect(
        tester: tester,
        candidateState: const CandidateAuthState(
          status: AuthStatus.unauthenticated,
        ),
        companyState: const CompanyAuthState(
          status: AuthStatus.unauthenticated,
        ),
        recruiterState: RecruiterAuthState(
          status: AuthStatus.authenticated,
          recruiter: _recruiter(uid: 'rec-1', companyId: 'comp-1'),
        ),
        matchedLocation: '/recruiter-login',
        uri: Uri.parse('/recruiter-login'),
      );

      if (FeatureFlags.recruiterModule) {
        expect(redirect, '/recruiter/rec-1/dashboard');
      } else {
        expect(redirect, '/');
      }
    });
  });
}

Future<String?> _evaluateRedirect({
  required WidgetTester tester,
  required CandidateAuthState candidateState,
  required CompanyAuthState companyState,
  required RecruiterAuthState recruiterState,
  required String matchedLocation,
  required Uri uri,
  Map<String, String> pathParameters = const <String, String>{},
}) async {
  final candidateCubit = _MockCandidateAuthCubit();
  final companyCubit = _MockCompanyAuthCubit();
  final recruiterCubit = _MockRecruiterAuthCubit();
  final goRouterState = _MockGoRouterState();

  when(() => candidateCubit.state).thenReturn(candidateState);
  when(() => companyCubit.state).thenReturn(companyState);
  when(() => recruiterCubit.state).thenReturn(recruiterState);
  when(() => goRouterState.matchedLocation).thenReturn(matchedLocation);
  when(() => goRouterState.uri).thenReturn(uri);
  when(() => goRouterState.pathParameters).thenReturn(pathParameters);

  String? redirect;
  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CandidateAuthCubit>.value(value: candidateCubit),
        RepositoryProvider<CompanyAuthCubit>.value(value: companyCubit),
        RepositoryProvider<RecruiterAuthCubit>.value(value: recruiterCubit),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            redirect = appAuthRedirect(
              context: context,
              state: goRouterState,
              authBootstrapPath: '/_auth-bootstrap',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  return redirect;
}

Candidate _candidate({required String uid}) {
  return Candidate(
    id: 1,
    name: 'Ana',
    lastName: 'Perez',
    email: 'ana@example.com',
    uid: uid,
    role: 'candidate',
  );
}

Company _company({required String uid}) {
  return Company(id: 1, name: 'Acme', email: 'acme@example.com', uid: uid);
}

Recruiter _recruiter({required String uid, required String companyId}) {
  return Recruiter(
    uid: uid,
    companyId: companyId,
    email: 'recruiter@example.com',
    name: 'Recruiter',
    role: RecruiterRole.admin,
    status: RecruiterStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}
