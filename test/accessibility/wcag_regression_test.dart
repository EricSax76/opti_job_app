import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/core/widgets/ai_generated_label.dart';
import 'package:opti_job_app/core/widgets/auth_login_form.dart';
import 'package:opti_job_app/core/widgets/auth_register_form.dart';
import 'package:opti_job_app/modules/companies/models/company_dashboard_navigation.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/dashboard/company_dashboard_sidebar.dart';
import 'package:opti_job_app/modules/compliance/cubits/data_requests_cubit.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart';

void main() {
  group('WCAG regression', () {
    testWidgets('AuthLoginForm mantiene labels, tap targets y contraste', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthLoginForm(
              tagline: 'Accede',
              title: 'Iniciar sesión',
              subtitle: 'Acceso para candidatos y empresas',
              emailIcon: Icons.mail_outline,
              isLoading: false,
              onSubmit: (_, _) {},
              onRegister: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('AuthRegisterForm permite navegación por teclado', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthRegisterForm(
              tagline: 'Registro',
              title: 'Crear cuenta',
              subtitle: 'Alta de usuario',
              nameLabel: 'Nombre',
              nameIcon: Icons.person_outline,
              emailIcon: Icons.mail_outline,
              isLoading: false,
              onSubmit: (_, _, _) {},
              onLogin: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusLabel = FocusManager.instance.primaryFocus?.debugLabel ?? '';
      expect(focusLabel, contains('register_email'));
    });

    testWidgets('Company sidebar conserva semántica de navegación', (
      tester,
    ) async {
      final items = companyDashboardNavItems(interviewsEnabled: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider(
              create: (_) => ThemeCubit(),
              child: CompanyDashboardSidebar(
                selectedIndex: 0,
                items: items,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Menú lateral de empresa'), findsOneWidget);
      expect(find.bySemanticsLabel('Home'), findsWidgets);
      expect(find.bySemanticsLabel('Publicar oferta'), findsWidgets);
    });

    testWidgets(
      'Candidate privacy portal mantiene acciones ARSULIPO accesibles',
      (tester) async {
        final cubit = DataRequestsCubit(
          repository: _FakeDataRequestRepository(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: cubit,
              child: const CandidatePrivacyPortalScreen(
                candidateUid: 'candidate_wcag',
                enableDecisionContextSection: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tus derechos ARSULIPO'), findsOneWidget);
        expect(find.byTooltip('Exportar mis datos'), findsOneWidget);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      },
    );

    testWidgets('Etiqueta IA expone semántica de transparencia', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AiGeneratedLabel(),
            ),
          ),
        ),
      );

      final semanticsNode = tester.getSemantics(find.byType(AiGeneratedLabel));
      expect(semanticsNode.label, contains('Contenido generado por IA'));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semanticsHandle.dispose();
    });
  });
}

class _FakeDataRequestRepository implements DataRequestRepository {
  @override
  Stream<List<DataRequest>> getAllRequests() => Stream.value(const []);

  @override
  Stream<List<DataRequest>> getRequests(String candidateUid) =>
      Stream.value(const []);

  @override
  Future<DataRequest> submitRequest(DataRequest request) async => request;

  @override
  Future<void> updateRequestStatus(
    String requestId,
    DataRequestStatus status, {
    String? response,
    String? processedBy,
  }) async {}
}
