import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_settings_screen.dart';

void main() {
  testWidgets('renderiza los campos base de la sección ajustes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CandidateSettingsScreen()));

    expect(find.text('Ajustes'), findsOneWidget);
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
}
