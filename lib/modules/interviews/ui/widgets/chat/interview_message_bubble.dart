import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_message_bubble_logic.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';

class InterviewMessageBubble extends StatelessWidget {
  const InterviewMessageBubble({
    super.key,
    required this.message,
    required this.currentUid,
    required this.onRespondToProposal,
  });

  final InterviewMessage message;
  final String? currentUid;
  final void Function(String proposalId, bool accept) onRespondToProposal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = InterviewMessageBubbleLogic.buildViewModel(
      message: message,
      currentUid: currentUid,
    );

    if (viewModel.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: uiSpacing8),
          padding: const EdgeInsets.symmetric(
            horizontal: uiSpacing12,
            vertical: uiSpacing4,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(uiSpacing12),
          ),
          child: Text(
            viewModel.content,
            style: const TextStyle(fontSize: uiSpacing12),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: uiSpacing4,
          horizontal: uiSpacing8,
        ),
        padding: const EdgeInsets.all(uiSpacing12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(uiSpacing12),
          border: viewModel.isProposal
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.35))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (viewModel.isProposal) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: uiSpacing16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: uiSpacing8),
                  Text(
                    'Propuesta de entrevista',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: uiSpacing8),
              if (viewModel.proposalDateText case final proposalDateText?)
                Text(
                  proposalDateText,
                  style: const TextStyle(
                    fontSize: uiSpacing16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: uiSpacing8),
            ],
            Text(viewModel.content),
            if (viewModel.showProposalActions) ...[
              const SizedBox(height: uiSpacing12),
              Wrap(
                spacing: uiSpacing8,
                runSpacing: uiSpacing8,
                children: [
                  FilledButton.icon(
                    onPressed: () => onRespondToProposal(message.id, true),
                    icon: const Icon(Icons.check, size: uiSpacing16 + 2),
                    label: const Text('Aceptar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(0, uiSpacing32 + uiSpacing8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onRespondToProposal(message.id, false),
                    icon: const Icon(Icons.close, size: uiSpacing16 + 2),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      minimumSize: const Size(0, uiSpacing32 + uiSpacing8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: uiSpacing4),
            Text(
              viewModel.createdAtText,
              style: TextStyle(
                fontSize: uiSpacing8 + 2,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
