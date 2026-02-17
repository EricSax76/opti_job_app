import 'package:flutter/material.dart';
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
    final viewModel = InterviewMessageBubbleLogic.buildViewModel(
      message: message,
      currentUid: currentUid,
    );

    if (viewModel.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(viewModel.content, style: const TextStyle(fontSize: 12)),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: viewModel.isProposal
              ? Border.all(color: Colors.blue.shade200)
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
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Propuesta de entrevista',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (viewModel.proposalDateText case final proposalDateText?)
                Text(
                  proposalDateText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            Text(viewModel.content),
            if (viewModel.showProposalActions) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => onRespondToProposal(message.id, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aceptar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onRespondToProposal(message.id, false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 40),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              viewModel.createdAtText,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
