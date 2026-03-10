import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/evaluations/logic/approval_flow_logic.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';

class ApprovalFlowContent extends StatelessWidget {
  const ApprovalFlowContent({
    super.key,
    required this.approval,
    this.currentUid,
    this.onApproveApprover,
    this.onRejectApprover,
  });

  final Approval approval;
  final String? currentUid;
  final Future<void> Function(Approver approver)? onApproveApprover;
  final Future<void> Function(Approver approver)? onRejectApprover;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: uiSpacing16),
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ApprovalHeader(approval: approval),
          const Divider(height: uiSpacing24),
          ...approval.approvers.map(
            (approver) => _ApproverRow(
              approver: approver,
              currentUid: currentUid,
              onApprove: onApproveApprover,
              onReject: onRejectApprover,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalHeader extends StatelessWidget {
  const _ApprovalHeader({required this.approval});

  final Approval approval;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(
          ApprovalFlowLogic.approvalTypeIcon(approval.type),
          color: _statusColor(context, approval.status),
        ),
        const SizedBox(width: uiSpacing8),
        Text(
          ApprovalFlowLogic.approvalTypeLabel(approval.type),
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _StatusBadge(status: approval.status),
      ],
    );
  }
}

class _ApproverRow extends StatelessWidget {
  const _ApproverRow({
    required this.approver,
    required this.currentUid,
    this.onApprove,
    this.onReject,
  });

  final Approver approver;
  final String? currentUid;
  final Future<void> Function(Approver approver)? onApprove;
  final Future<void> Function(Approver approver)? onReject;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = ApprovalFlowLogic.approverDisplayName(
      approver: approver,
      currentUid: currentUid,
    );
    final notes = ApprovalFlowLogic.approverNotes(approver);
    final decidedAt = ApprovalFlowLogic.formatDecisionDate(approver.decidedAt);
    final canCurrentUserDecide = ApprovalFlowLogic.canCurrentUserDecide(
      approver: approver,
      currentUid: currentUid,
      hasDecisionHandlers: onApprove != null && onReject != null,
    );
    final normalizedCurrentUid = currentUid?.trim() ?? '';
    final isCurrentUser =
        normalizedCurrentUid.isNotEmpty && approver.uid == normalizedCurrentUid;

    return Padding(
      padding: const EdgeInsets.only(bottom: uiSpacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _statusColor(
                  context,
                  approver.status,
                ).withValues(alpha: 0.2),
                child: Icon(
                  ApprovalFlowLogic.statusIcon(approver.status),
                  size: 14,
                  color: _statusColor(context, approver.status),
                ),
              ),
              const SizedBox(width: uiSpacing12),
              Expanded(
                child: Text(
                  displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrentUser
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (decidedAt.isNotEmpty)
                Text(decidedAt, style: textTheme.bodySmall),
            ],
          ),
          if (notes != null)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: uiSpacing4),
              child: Text(
                notes,
                style: textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (canCurrentUserDecide)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: uiSpacing8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (onApprove == null) return;
                      await onApprove!(approver);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: uiSpacing8),
                  OutlinedButton(
                    onPressed: () async {
                      if (onReject == null) return;
                      await onReject!(approver);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return InfoPill(
      label: status.name.toUpperCase(),
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      textColor: color,
    );
  }
}

Color _statusColor(BuildContext context, ApprovalStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    ApprovalStatus.approved => scheme.tertiary,
    ApprovalStatus.rejected => scheme.error,
    ApprovalStatus.pending => scheme.secondary,
  };
}
