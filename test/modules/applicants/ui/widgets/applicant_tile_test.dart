import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_tile.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';

void main() {
  group('ApplicantTile', () {
    const application = Application(
      id: 'app1',
      jobOfferId: 'job1',
      candidateUid: 'uid1',
      candidateName: 'John Doe',
      candidateEmail: 'john@example.com',
      status: 'submitted',
    );

    testWidgets('renders candidate info correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicantTile(
              application: application,
              onTap: () {},
              onStatusChanged: (_) {},
              onStartInterview: () {},
            ),
          ),
        ),
      );

      expect(find.text('Candidato #UID1'), findsOneWidget);
      expect(
        find.textContaining('Identidad oculta hasta etapas avanzadas'),
        findsOneWidget,
      );
      expect(find.textContaining('Estado: Postulado'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicantTile(
              application: application,
              onTap: () => tapped = true,
              onStatusChanged: (_) {},
              onStartInterview: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows actions when callbacks provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicantTile(
              application: application,
              onTap: () {},
              onStatusChanged: (_) {},
              onStartInterview: () {},
            ),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('hides actions when callbacks are null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicantTile(
              application: application,
              onTap: () {},
              onStatusChanged: null,
              onStartInterview: null,
            ),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });
}
