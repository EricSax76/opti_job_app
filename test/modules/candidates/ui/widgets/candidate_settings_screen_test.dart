import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';
import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_settings_screen.dart';

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
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithEudiWallet({
    required EudiWalletSignInInput input,
  }) async {}

  @override
  Future<void> restoreSession() async {}
}

void main() {
  testWidgets('renderiza los campos base de la sección ajustes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CandidateAuthCubit>(
            create: (_) => _StubCandidateAuthCubit(),
          ),
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        ],
        child: const MaterialApp(home: CandidateSettingsScreen()),
      ),
    );

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Modo enfoque'), findsOneWidget);
    expect(find.text('Datos de acceso'), findsOneWidget);
    expect(find.text('Cambiar email'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Notificaciones y consejos'), findsOneWidget);
    expect(find.text('Alertas de empleo por email'), findsOneWidget);
    expect(find.text('Configura tus comunicaciones'), findsOneWidget);
    expect(find.text('Privacidad'), findsOneWidget);
    expect(find.text('Qué ven las empresas'), findsOneWidget);
    expect(find.text('Bloquear empresas'), findsOneWidget);
    expect(find.text('Promociones de nuestros productos'), findsOneWidget);
    expect(find.text('Publicidad programática'), findsOneWidget);
    expect(find.text('Cómo gestionamos tus datos'), findsOneWidget);
    expect(find.text('Descarga una copia de tus datos.'), findsOneWidget);
  });

  testWidgets('permite activar modo enfoque desde ajustes', (tester) async {
    final themeCubit = ThemeCubit();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CandidateAuthCubit>(
            create: (_) => _StubCandidateAuthCubit(),
          ),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: const MaterialApp(home: CandidateSettingsScreen()),
      ),
    );

    expect(themeCubit.state.focusModeEnabled, isFalse);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(themeCubit.state.focusModeEnabled, isTrue);
  });
}
