import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/evaluations/logic/approval_flow_logic.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';

void main() {
  group('ApprovalFlowLogic', () {
    test('approvalTypeLabel returns expected labels', () {
      expect(
        ApprovalFlowLogic.approvalTypeLabel(ApprovalType.offerApproval),
        'Offer Approval',
      );
      expect(
        ApprovalFlowLogic.approvalTypeLabel(ApprovalType.salaryApproval),
        'Salary Approval',
      );
    });

    test('approvalTypeIcon returns expected icons', () {
      expect(
        ApprovalFlowLogic.approvalTypeIcon(ApprovalType.offerApproval),
        Icons.assignment_turned_in,
      );
      expect(
        ApprovalFlowLogic.approvalTypeIcon(ApprovalType.salaryApproval),
        Icons.monetization_on,
      );
    });

    test('statusIcon returns expected icons', () {
      expect(
        ApprovalFlowLogic.statusIcon(ApprovalStatus.approved),
        Icons.check,
      );
      expect(
        ApprovalFlowLogic.statusIcon(ApprovalStatus.rejected),
        Icons.close,
      );
      expect(
        ApprovalFlowLogic.statusIcon(ApprovalStatus.pending),
        Icons.access_time,
      );
    });

    test('canCurrentUserDecide only when matching uid and pending', () {
      const pendingApprover = Approver(
        uid: 'user-1',
        name: 'Ana',
        status: ApprovalStatus.pending,
      );
      const approvedApprover = Approver(
        uid: 'user-1',
        name: 'Ana',
        status: ApprovalStatus.approved,
      );

      expect(
        ApprovalFlowLogic.canCurrentUserDecide(
          approver: pendingApprover,
          currentUid: ' user-1 ',
          hasDecisionHandlers: true,
        ),
        isTrue,
      );
      expect(
        ApprovalFlowLogic.canCurrentUserDecide(
          approver: pendingApprover,
          currentUid: 'user-2',
          hasDecisionHandlers: true,
        ),
        isFalse,
      );
      expect(
        ApprovalFlowLogic.canCurrentUserDecide(
          approver: approvedApprover,
          currentUid: 'user-1',
          hasDecisionHandlers: true,
        ),
        isFalse,
      );
      expect(
        ApprovalFlowLogic.canCurrentUserDecide(
          approver: pendingApprover,
          currentUid: 'user-1',
          hasDecisionHandlers: false,
        ),
        isFalse,
      );
    });

    test('approverDisplayName appends (You) only for current user', () {
      const approver = Approver(
        uid: 'user-1',
        name: 'Ana',
        status: ApprovalStatus.pending,
      );

      expect(
        ApprovalFlowLogic.approverDisplayName(
          approver: approver,
          currentUid: ' user-1 ',
        ),
        'Ana (You)',
      );
      expect(
        ApprovalFlowLogic.approverDisplayName(
          approver: approver,
          currentUid: 'other',
        ),
        'Ana',
      );
    });

    test('approverNotes trims text and returns null when empty', () {
      const approverWithNotes = Approver(
        uid: 'user-1',
        name: 'Ana',
        status: ApprovalStatus.pending,
        notes: '  detalle  ',
      );
      const approverWithoutNotes = Approver(
        uid: 'user-1',
        name: 'Ana',
        status: ApprovalStatus.pending,
        notes: '   ',
      );

      expect(ApprovalFlowLogic.approverNotes(approverWithNotes), 'detalle');
      expect(ApprovalFlowLogic.approverNotes(approverWithoutNotes), isNull);
    });

    test('formatDecisionDate returns expected formatted date', () {
      final date = DateTime(2026, 3, 10, 9, 5);
      expect(ApprovalFlowLogic.formatDecisionDate(date), '10/3 9:05');
      expect(ApprovalFlowLogic.formatDecisionDate(null), '');
    });
  });
}
