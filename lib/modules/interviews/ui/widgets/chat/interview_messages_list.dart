import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_message_bubble.dart';

class InterviewMessagesList extends StatelessWidget {
  const InterviewMessagesList({
    super.key,
    required this.messages,
    required this.currentUid,
    required this.onRespondToProposal,
  });

  final List<InterviewMessage> messages;
  final String? currentUid;
  final void Function(String proposalId, bool accept) onRespondToProposal;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Text('No hay mensajes aún.'));
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return InterviewMessageBubble(
          message: message,
          currentUid: currentUid,
          onRespondToProposal: onRespondToProposal,
        );
      },
    );
  }
}
