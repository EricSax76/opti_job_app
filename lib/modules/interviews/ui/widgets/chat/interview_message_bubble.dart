import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';

class InterviewMessageBubble extends StatelessWidget {
  const InterviewMessageBubble({super.key, required this.message});

  final InterviewMessage message;

  @override
  Widget build(BuildContext context) {
    try {
      return _buildBubble(context);
    } catch (_) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Text('No se pudo renderizar este mensaje.'),
        ),
      );
    }
  }

  Widget _buildBubble(BuildContext context) {
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(message.content, style: const TextStyle(fontSize: 12)),
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
          border: message.type == MessageType.proposal
              ? Border.all(color: Colors.blue.shade200)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.proposal) ...[
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
              if (message.metadata?.proposedAt case final proposedAt?)
                Text(
                  _safeFormatDateTime(proposedAt, 'EEEE d MMM, h:mm a'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            Text(message.content),
            if (message.type == MessageType.proposal) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _respondToProposal(context, accept: true),
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
                    onPressed: () => _respondToProposal(context, accept: false),
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
              _safeFormatDateTime(message.createdAt, 'jm'),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _respondToProposal(BuildContext context, {required bool accept}) {
    context.read<InterviewSessionCubit>().respondToSlot(message.id, accept);
  }

  String _safeFormatDateTime(DateTime date, String pattern) {
    try {
      return DateFormat(pattern).format(date);
    } catch (_) {
      return date.toLocal().toIso8601String();
    }
  }
}
