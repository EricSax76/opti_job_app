import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/core/widgets/auth_register_form.dart';

void main() {
  testWidgets(
    'bloquea registro sin aceptar privacidad/cookies y permite continuar tras aceptar',
    (tester) async {
      var submitCount = 0;

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
              onSubmit: (_, _, _) => submitCount += 1,
              onLogin: () {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Ana Dev');
      await tester.enterText(find.byType(TextFormField).at(1), 'ana@test.com');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');
      await tester.enterText(find.byType(TextFormField).at(3), '123456');

      final submitButton = find.widgetWithText(FilledButton, 'Crear cuenta');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(submitCount, 0);
      expect(
        find.textContaining('Debes aceptar la Política de Privacidad'),
        findsOneWidget,
      );

      final privacyCheckbox = find.byType(CheckboxListTile).at(0);
      final cookiesCheckbox = find.byType(CheckboxListTile).at(1);
      await tester.ensureVisible(privacyCheckbox);
      await tester.tap(privacyCheckbox);
      await tester.pump();
      await tester.ensureVisible(cookiesCheckbox);
      await tester.tap(cookiesCheckbox);
      await tester.pump();

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(submitCount, 1);
    },
  );
}
