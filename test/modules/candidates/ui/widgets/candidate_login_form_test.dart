import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_login_form.dart';

void main() {
  testWidgets(
    'renderiza acciones de acceso con Google y EUDI en login candidato',
    (tester) async {
      var googleTapCount = 0;
      var eudiTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CandidateLoginForm(
              isLoading: false,
              onSubmit: (_, _) {},
              onRegister: () {},
              onGoogleSignIn: () => googleTapCount += 1,
              onEudiWallet: () => eudiTapCount += 1,
            ),
          ),
        ),
      );

      expect(find.text('Accede con Google'), findsOneWidget);
      expect(find.text('Entrar con EUDI Wallet'), findsOneWidget);

      await tester.tap(find.text('Accede con Google'));
      await tester.pump();
      expect(googleTapCount, 1);

      await tester.tap(find.text('Entrar con EUDI Wallet'));
      await tester.pump();
      expect(eudiTapCount, 1);
    },
  );
}
