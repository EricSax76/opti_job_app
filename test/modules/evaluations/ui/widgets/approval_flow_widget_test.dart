import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/approval_flow_widget.dart';

void main() {
  group('ApprovalFlowWidget', () {
    testWidgets('renders approval metadata and pending badge', (tester) async {
      final approval = _buildApproval(
        type: ApprovalType.offerApproval,
        status: ApprovalStatus.pending,
        approvers: const [
          Approver(uid: 'user-1', name: 'Ana', status: ApprovalStatus.pending),
        ],
      );

      await tester.pumpWidget(_buildWidget(approval: approval));

      expect(find.text('Offer Approval'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('shows actions only for current pending approver', (
      tester,
    ) async {
      final approval = _buildApproval(
        approvers: const [
          Approver(uid: 'user-1', name: 'Ana', status: ApprovalStatus.pending),
          Approver(
            uid: 'user-2',
            name: 'Luis',
            status: ApprovalStatus.approved,
          ),
        ],
      );

      await tester.pumpWidget(
        _buildWidget(
          approval: approval,
          currentUid: 'user-1',
          onDecision: (_, _) async {},
        ),
      );

      expect(find.text('Ana (You)'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Luis'), findsOneWidget);
    });

    testWidgets('does not show actions when onDecision is null', (
      tester,
    ) async {
      final approval = _buildApproval(
        approvers: const [
          Approver(uid: 'user-1', name: 'Ana', status: ApprovalStatus.pending),
        ],
      );

      await tester.pumpWidget(
        _buildWidget(approval: approval, currentUid: 'user-1'),
      );

      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets(
      'Approve triggers callback with approved status and null notes',
      (tester) async {
        final approval = _buildApproval(
          approvers: const [
            Approver(
              uid: 'user-1',
              name: 'Ana',
              status: ApprovalStatus.pending,
            ),
          ],
        );
        final calls = <_DecisionCall>[];

        await tester.pumpWidget(
          _buildWidget(
            approval: approval,
            currentUid: 'user-1',
            onDecision: (status, notes) async {
              calls.add(_DecisionCall(status: status, notes: notes));
            },
          ),
        );

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(calls, hasLength(1));
        expect(calls.first.status, ApprovalStatus.approved);
        expect(calls.first.notes, isNull);
      },
    );

    testWidgets('Reject opens dialog and sends notes on confirmation', (
      tester,
    ) async {
      final approval = _buildApproval(
        approvers: const [
          Approver(uid: 'user-1', name: 'Ana', status: ApprovalStatus.pending),
        ],
      );
      final calls = <_DecisionCall>[];

      await tester.pumpWidget(
        _buildWidget(
          approval: approval,
          currentUid: 'user-1',
          onDecision: (status, notes) async {
            calls.add(_DecisionCall(status: status, notes: notes));
          },
        ),
      );

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'No cumple criterios',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(ElevatedButton, 'Reject'),
        ),
      );
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.first.status, ApprovalStatus.rejected);
      expect(calls.first.notes, 'No cumple criterios');
    });
  });
}

Approval _buildApproval({
  ApprovalType type = ApprovalType.offerApproval,
  ApprovalStatus status = ApprovalStatus.pending,
  List<Approver> approvers = const [],
}) {
  return Approval(
    id: 'approval-1',
    applicationId: 'application-1',
    jobOfferId: 'offer-1',
    companyId: 'company-1',
    type: type,
    requestedBy: 'user-requester',
    approvers: approvers,
    status: status,
    createdAt: DateTime(2026, 3, 10),
  );
}

Widget _buildWidget({
  required Approval approval,
  String? currentUid,
  Future<void> Function(ApprovalStatus status, String? notes)? onDecision,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ApprovalFlowWidget(
        approval: approval,
        currentUid: currentUid,
        onDecision: onDecision,
      ),
    ),
  );
}

class _DecisionCall {
  const _DecisionCall({required this.status, required this.notes});

  final ApprovalStatus status;
  final String? notes;
}
