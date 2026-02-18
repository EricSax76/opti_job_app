import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';

void main() {
  testWidgets('places sidebar at the start by default on wide layouts', (
    tester,
  ) async {
    final bodyKey = GlobalKey();
    final sidebarKey = GlobalKey();

    await tester.pumpWidget(
      _buildHarness(bodyKey: bodyKey, sidebarKey: sidebarKey),
    );
    await tester.pumpAndSettle();

    final bodyX = tester.getTopLeft(find.byKey(bodyKey)).dx;
    final sidebarX = tester.getTopLeft(find.byKey(sidebarKey)).dx;

    expect(sidebarX, lessThan(bodyX));
  });

  testWidgets('places sidebar at the end when configured', (tester) async {
    final bodyKey = GlobalKey();
    final sidebarKey = GlobalKey();

    await tester.pumpWidget(
      _buildHarness(
        bodyKey: bodyKey,
        sidebarKey: sidebarKey,
        alignment: CoreShellSidebarAlignment.end,
      ),
    );
    await tester.pumpAndSettle();

    final bodyX = tester.getTopLeft(find.byKey(bodyKey)).dx;
    final sidebarX = tester.getTopLeft(find.byKey(sidebarKey)).dx;

    expect(sidebarX, greaterThan(bodyX));
  });
}

Widget _buildHarness({
  required GlobalKey bodyKey,
  required GlobalKey sidebarKey,
  CoreShellSidebarAlignment alignment = CoreShellSidebarAlignment.start,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(1200, 800)),
      child: CoreShell(
        showAppBar: false,
        sidebarAlignment: alignment,
        sidebar: SizedBox(
          key: sidebarKey,
          width: 260,
          child: const ColoredBox(color: Colors.blue),
        ),
        body: SizedBox.expand(
          key: bodyKey,
          child: const ColoredBox(color: Colors.red),
        ),
      ),
    ),
  );
}
