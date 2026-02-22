import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_dashboard_app_bar.dart';

void main() {
  testWidgets('menu del avatar muestra ajustes y ejecuta su callback', (
    tester,
  ) async {
    var openedSettings = false;

    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: candidateDashboardTabItems.length,
          child: Builder(
            builder: (context) => Scaffold(
              appBar: CandidateDashboardAppBar(
                tabController: DefaultTabController.of(context),
                avatarUrl: null,
                accountDisplayName: 'Candidato',
                onOpenSettings: () => openedSettings = true,
                onOpenProfile: () {},
                onLogout: () {},
                showTabBar: false,
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    expect(openedSettings, isTrue);
  });
}
