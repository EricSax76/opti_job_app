import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';
import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_sidebar.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

void main() {
  testWidgets(
    'expands collapsed sidebar when tapping anywhere on its surface',
    (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider<CandidateAuthCubit>(
              create: (_) => _StubCandidateAuthCubit(),
            ),
            BlocProvider<InterviewListCubit>(
              create: (_) => _StubInterviewListCubit(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 160,
                height: 700,
                child: CandidateDashboardSidebar(
                  selectedIndex: 0,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byTooltip('Colapsar'), findsOneWidget);

      await tester.tap(find.byTooltip('Colapsar'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Expandir'), findsOneWidget);

      final sidebarRect = tester.getRect(
        find.byType(CandidateDashboardSidebar),
      );
      await tester.tapAt(sidebarRect.center);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Colapsar'), findsOneWidget);
    },
  );
}

class _StubCandidateAuthCubit extends Cubit<CandidateAuthState>
    implements CandidateAuthCubit {
  _StubCandidateAuthCubit()
    : super(const CandidateAuthState(status: AuthStatus.authenticated));

  @override
  void clearError() {}

  @override
  void completeOnboarding() {}

  @override
  Future<void> loginCandidate({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithEudiWallet({
    required EudiWalletSignInInput input,
  }) async {}

  @override
  Future<void> restoreSession() async {}
}

class _StubInterviewListCubit extends Cubit<InterviewListState>
    implements InterviewListCubit {
  _StubInterviewListCubit() : super(InterviewListInitial());

  @override
  Future<void> refresh() async {}

  @override
  void retry() {}

  @override
  Future<void> start() async {}
}
