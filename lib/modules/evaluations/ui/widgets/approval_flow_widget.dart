import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';

class ApprovalFlowWidget extends StatelessWidget {
  const ApprovalFlowWidget({
    super.key,
    required this.approval,
    this.onDecision,
    this.currentUid,
  });

  final Approval approval;
  final Function(ApprovalStatus status, String? notes)? onDecision;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: uiSpacing16),
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                approval.type == ApprovalType.offerApproval
                    ? Icons.assignment_turned_in
                    : Icons.monetization_on,
                color: _getStatusColor(context, approval.status),
              ),
              const SizedBox(width: uiSpacing8),
              Text(
                approval.type == ApprovalType.offerApproval
                    ? 'Offer Approval'
                    : 'Salary Approval',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _StatusBadge(status: approval.status),
            ],
          ),
          const Divider(height: uiSpacing24),
          ...approval.approvers.map((approver) {
            final isMe = approver.uid == currentUid;
            final isPending = approver.status == ApprovalStatus.pending;

            return Padding(
              padding: const EdgeInsets.only(bottom: uiSpacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: _getStatusColor(
                          context,
                          approver.status,
                        ).withValues(alpha: 0.2),
                        child: Icon(
                          _getStatusIcon(approver.status),
                          size: 14,
                          color: _getStatusColor(context, approver.status),
                        ),
                      ),
                      const SizedBox(width: uiSpacing12),
                      Expanded(
                        child: Text(
                          approver.name + (isMe ? ' (You)' : ''),
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (approver.decidedAt != null)
                        Text(
                          _formatDate(approver.decidedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  if (approver.notes != null && approver.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: uiSpacing4),
                      child: Text(
                        approver.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (isMe && isPending && onDecision != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: uiSpacing8),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                onDecision!(ApprovalStatus.approved, null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.tertiary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onTertiary,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: uiSpacing8),
                          OutlinedButton(
                            onPressed: () => _showRejectDialog(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
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
          }),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Approval'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDecision!(ApprovalStatus.rejected, controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, ApprovalStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case ApprovalStatus.approved:
        return scheme.tertiary;
      case ApprovalStatus.rejected:
        return scheme.error;
      case ApprovalStatus.pending:
        return scheme.secondary;
    }
  }

  IconData _getStatusIcon(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.approved:
        return Icons.check;
      case ApprovalStatus.rejected:
        return Icons.close;
      case ApprovalStatus.pending:
        return Icons.access_time;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return InfoPill(
      label: status.name.toUpperCase(),
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      textColor: color,
    );
  }

  Color _getColor(BuildContext context) {
    switch (status) {
      case ApprovalStatus.approved:
        return Theme.of(context).colorScheme.tertiary;
      case ApprovalStatus.rejected:
        return Theme.of(context).colorScheme.error;
      case ApprovalStatus.pending:
        return Theme.of(context).colorScheme.secondary;
    }
  }
}
