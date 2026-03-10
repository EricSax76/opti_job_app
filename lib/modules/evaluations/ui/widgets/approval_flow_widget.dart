import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/evaluations/logic/approval_flow_logic.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/approval_flow_content.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/approval_flow_dialogs.dart';

class ApprovalFlowWidget extends StatelessWidget {
  const ApprovalFlowWidget({
    super.key,
    required this.approval,
    this.onDecision,
    this.currentUid,
  });

  final Approval approval;
  final Future<void> Function(ApprovalStatus status, String? notes)? onDecision;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    return ApprovalFlowContent(
      approval: approval,
      currentUid: currentUid,
      onApproveApprover: _hasDecisionHandler ? _handleApproveDecision : null,
      onRejectApprover: _hasDecisionHandler
          ? (approver) => _handleRejectDecision(context, approver)
          : null,
    );
  }

  bool get _hasDecisionHandler => onDecision != null;

  bool _canCurrentUserDecide(Approver approver) {
    return ApprovalFlowLogic.canCurrentUserDecide(
      approver: approver,
      currentUid: currentUid,
      hasDecisionHandlers: _hasDecisionHandler,
    );
  }

  Future<void> _handleApproveDecision(Approver approver) async {
    if (!_canCurrentUserDecide(approver)) return;
    await onDecision?.call(ApprovalStatus.approved, null);
  }

  Future<void> _handleRejectDecision(
    BuildContext context,
    Approver approver,
  ) async {
    if (!_canCurrentUserDecide(approver)) return;

    final notes = await showApprovalRejectDialog(context);
    if (!context.mounted || notes == null) return;
    await onDecision?.call(ApprovalStatus.rejected, notes);
  }
}
