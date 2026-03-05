import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/features/onboarding/view/containers/onboarding_container.dart';
import 'package:opti_job_app/features/onboarding/view/widgets/onboarding_card_base/widgets/onboarding_primary_button.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/models/company_compliance_profile.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_state.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _TestCandidateAuthCubit extends Cubit<CandidateAuthState>
    implements CandidateAuthCubit {
  _TestCandidateAuthCubit(super.initialState);

  int completeOnboardingCallCount = 0;

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> loginCandidate({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithEudiWallet({
    required EudiWalletSignInInput input,
  }) async {}

  @override
  void completeOnboarding() {
    completeOnboardingCallCount += 1;
    emit(state.copyWith(needsOnboarding: false));
  }

  @override
  void clearError() {}

  @override
  Future<void> logout() async {}
}

class _TestCompanyAuthCubit extends Cubit<CompanyAuthState>
    implements CompanyAuthCubit {
  _TestCompanyAuthCubit(super.initialState);

  int completeOnboardingCallCount = 0;

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> loginCompany({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  void completeOnboarding() {
    completeOnboardingCallCount += 1;
    emit(state.copyWith(needsOnboarding: false));
  }

  @override
  void clearError() {}

  @override
  Future<void> logout() async {}

  @override
  void updateCompany(Company company) {}
}

class _TestProfileCubit extends Cubit<ProfileState> implements ProfileCubit {
  _TestProfileCubit(super.initialState);

  int refreshCallCount = 0;

  @override
  Future<void> start() async {}

  @override
  Future<void> refresh() async {
    refreshCallCount += 1;
  }

  @override
  void retry() {}

  @override
  Future<void> updateCandidateProfile({
    required String name,
    required String lastName,
    Uint8List? avatarBytes,
    CandidateOnboardingProfile? onboardingProfile,
  }) async {}
}

void main() {
  const authenticatedCandidate = Candidate(
    id: 1,
    name: 'Ana',
    lastName: 'Dev',
    email: 'ana@example.com',
    uid: 'candidate-1',
    role: 'candidate',
  );
  const authenticatedCompany = Company(
    id: 9,
    name: 'Acme',
    email: 'acme@example.com',
    uid: 'company-1',
  );

  setUpAll(() {
    registerFallbackValue(
      const CandidateOnboardingProfile(
        targetRole: '',
        preferredLocation: '',
        preferredModality: '',
        preferredSeniority: '',
        workStyleSkipped: true,
      ),
    );
    registerFallbackValue(const CompanyMultipostingSettings());
    registerFallbackValue(const CompanyComplianceProfile());
    registerFallbackValue(Uint8List(0));
  });

  group('OnboardingContainer', () {
    testWidgets(
      'candidate flow persists onboarding profile and navigates to dashboard',
      (tester) async {
        final profileRepository = _MockProfileRepository();
        final candidateAuthCubit = _TestCandidateAuthCubit(
          const CandidateAuthState(
            status: AuthStatus.authenticated,
            needsOnboarding: true,
            candidate: authenticatedCandidate,
          ),
        );
        final companyAuthCubit = _TestCompanyAuthCubit(
          const CompanyAuthState(status: AuthStatus.unauthenticated),
        );
        final profileCubit = _TestProfileCubit(
          const ProfileState(
            status: ProfileStatus.loaded,
            candidate: authenticatedCandidate,
          ),
        );

        late CandidateOnboardingProfile persistedProfile;
        when(
          () => profileRepository.saveCandidateOnboardingProfile(
            uid: any(named: 'uid'),
            onboardingProfile: any(named: 'onboardingProfile'),
          ),
        ).thenAnswer((invocation) async {
          persistedProfile =
              invocation.namedArguments[#onboardingProfile]
                  as CandidateOnboardingProfile;
          return authenticatedCandidate.copyWith(
            onboardingProfile: persistedProfile,
          );
        });

        await tester.pumpWidget(
          _buildHarness(
            profileRepository: profileRepository,
            candidateAuthCubit: candidateAuthCubit,
            companyAuthCubit: companyAuthCubit,
            profileCubit: profileCubit,
          ),
        );

        await _completeCandidateOnboardingFlow(tester);
        await tester.pumpAndSettle();

        expect(find.text('candidate-dashboard-candidate-1'), findsOneWidget);
        expect(candidateAuthCubit.completeOnboardingCallCount, 1);
        expect(profileCubit.refreshCallCount, 1);
        expect(persistedProfile.targetRole, 'Flutter Developer');
        expect(persistedProfile.preferredLocation, 'Madrid');
        expect(persistedProfile.preferredModality, 'Remoto');
        expect(persistedProfile.preferredSeniority, 'Mid');
        expect(persistedProfile.workStyleSkipped, isTrue);
        expect(persistedProfile.startOfDayPreference, isNull);
        expect(persistedProfile.feedbackPreference, isNull);
        expect(persistedProfile.structurePreference, isNull);
        expect(persistedProfile.taskPacePreference, isNull);

        verify(
          () => profileRepository.saveCandidateOnboardingProfile(
            uid: 'candidate-1',
            onboardingProfile: any(named: 'onboardingProfile'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'candidate flow keeps navigation non-blocking when persistence fails',
      (tester) async {
        final profileRepository = _MockProfileRepository();
        final candidateAuthCubit = _TestCandidateAuthCubit(
          const CandidateAuthState(
            status: AuthStatus.authenticated,
            needsOnboarding: true,
            candidate: authenticatedCandidate,
          ),
        );
        final companyAuthCubit = _TestCompanyAuthCubit(
          const CompanyAuthState(status: AuthStatus.unauthenticated),
        );
        final profileCubit = _TestProfileCubit(
          const ProfileState(
            status: ProfileStatus.loaded,
            candidate: authenticatedCandidate,
          ),
        );

        when(
          () => profileRepository.saveCandidateOnboardingProfile(
            uid: any(named: 'uid'),
            onboardingProfile: any(named: 'onboardingProfile'),
          ),
        ).thenThrow(Exception('firestore unavailable'));

        await tester.pumpWidget(
          _buildHarness(
            profileRepository: profileRepository,
            candidateAuthCubit: candidateAuthCubit,
            companyAuthCubit: companyAuthCubit,
            profileCubit: profileCubit,
          ),
        );

        await _completeCandidateOnboardingFlow(tester);
        await tester.pumpAndSettle();

        expect(find.text('candidate-dashboard-candidate-1'), findsOneWidget);
        expect(candidateAuthCubit.completeOnboardingCallCount, 1);
        expect(profileCubit.refreshCallCount, 0);
      },
    );

    testWidgets('company branch confirms and navigates to company dashboard', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final profileRepository = _MockProfileRepository();
      final candidateAuthCubit = _TestCandidateAuthCubit(
        const CandidateAuthState(status: AuthStatus.unauthenticated),
      );
      final companyAuthCubit = _TestCompanyAuthCubit(
        const CompanyAuthState(
          status: AuthStatus.authenticated,
          needsOnboarding: true,
          company: authenticatedCompany,
        ),
      );
      final profileCubit = _TestProfileCubit(
        const ProfileState(
          status: ProfileStatus.loaded,
          company: authenticatedCompany,
        ),
      );

      when(
        () => profileRepository.updateCompanyProfile(
          uid: any(named: 'uid'),
          name: any(named: 'name'),
          website: any(named: 'website'),
          industry: any(named: 'industry'),
          teamSize: any(named: 'teamSize'),
          headquarters: any(named: 'headquarters'),
          description: any(named: 'description'),
          multipostingSettings: any(named: 'multipostingSettings'),
          complianceProfile: any(named: 'complianceProfile'),
          avatarBytes: any(named: 'avatarBytes'),
        ),
      ).thenAnswer((_) async => authenticatedCompany);

      await tester.pumpWidget(
        _buildHarness(
          profileRepository: profileRepository,
          candidateAuthCubit: candidateAuthCubit,
          companyAuthCubit: companyAuthCubit,
          profileCubit: profileCubit,
        ),
      );

      expect(find.text('Hola, Acme 👋'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), 'Tecnologia');
      await tester.enterText(find.byType(TextFormField).at(2), '11-50');
      await tester.enterText(find.byType(TextFormField).at(3), 'Madrid');
      await tester.enterText(find.byType(TextFormField).at(5), 'Acme Labs SL');
      await tester.enterText(find.byType(TextFormField).at(6), 'B12345678');
      await tester.enterText(
        find.byType(TextFormField).at(7),
        'privacidad@acme.com',
      );
      await tester.enterText(find.byType(TextFormField).at(8), 'Laura DPO');
      await tester.enterText(find.byType(TextFormField).at(9), 'dpo@acme.com');
      await tester.enterText(
        find.byType(TextFormField).at(10),
        'https://acme.com/privacidad',
      );
      await tester.enterText(
        find.byType(TextFormField).at(11),
        'Conservamos datos de candidatos durante 36 meses.',
      );
      final primaryButton = find.byType(OnboardingPrimaryButton).first;
      await tester.dragUntilVisible(
        primaryButton,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(primaryButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('company-dashboard-company-1'), findsOneWidget);
      expect(companyAuthCubit.completeOnboardingCallCount, 1);
      verify(
        () => profileRepository.updateCompanyProfile(
          uid: 'company-1',
          name: 'Acme',
          website: any(named: 'website'),
          industry: 'Tecnologia',
          teamSize: '11-50',
          headquarters: 'Madrid',
          description: any(named: 'description'),
          multipostingSettings: any(named: 'multipostingSettings'),
          complianceProfile: any(named: 'complianceProfile'),
          avatarBytes: null,
        ),
      ).called(1);
      verifyNever(
        () => profileRepository.saveCandidateOnboardingProfile(
          uid: any(named: 'uid'),
          onboardingProfile: any(named: 'onboardingProfile'),
        ),
      );
    });
  });
}

Widget _buildHarness({
  required ProfileRepository profileRepository,
  required CandidateAuthCubit candidateAuthCubit,
  required CompanyAuthCubit companyAuthCubit,
  required ProfileCubit profileCubit,
}) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const Scaffold(body: OnboardingContainer()),
      ),
      GoRoute(
        path: '/candidate/:uid/dashboard',
        builder: (_, state) => Scaffold(
          body: Text('candidate-dashboard-${state.pathParameters['uid']}'),
        ),
      ),
      GoRoute(
        path: '/company/:uid/dashboard',
        builder: (_, state) => Scaffold(
          body: Text('company-dashboard-${state.pathParameters['uid']}'),
        ),
      ),
      GoRoute(
        path: '/CandidateDashboard',
        builder: (_, _) =>
            const Scaffold(body: Text('candidate-dashboard-legacy')),
      ),
      GoRoute(
        path: '/DashboardCompany',
        builder: (_, _) =>
            const Scaffold(body: Text('company-dashboard-legacy')),
      ),
    ],
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ProfileRepository>.value(value: profileRepository),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<CandidateAuthCubit>.value(value: candidateAuthCubit),
        BlocProvider<CompanyAuthCubit>.value(value: companyAuthCubit),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
}

Future<void> _completeCandidateOnboardingFlow(WidgetTester tester) async {
  await _tapVisibleText(tester, 'Siguiente');
  await _tapVisibleText(tester, 'Siguiente');
  await _tapVisibleText(tester, 'Continuar');
  await _tapVisibleText(tester, 'Saltar por ahora');

  await tester.enterText(
    find.byKey(const ValueKey('onboarding_target_role_input')),
    'Flutter Developer',
  );
  await tester.enterText(
    find.byKey(const ValueKey('onboarding_location_input')),
    'Madrid',
  );
  await _tapVisibleText(tester, 'Remoto');
  await _tapVisibleText(tester, 'Mid');
  await _tapVisibleText(tester, 'Finalizar onboarding');
}

Future<void> _tapVisibleText(WidgetTester tester, String label) async {
  final finder = find.text(label).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
