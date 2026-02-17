import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
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
      return const StateMessage(
        title: 'Sin mensajes',
        message: 'Todavia no hay mensajes en esta entrevista.',
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(uiSpacing16),
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
