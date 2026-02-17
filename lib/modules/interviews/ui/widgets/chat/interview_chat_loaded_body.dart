import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_meeting_banner.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_messages_list.dart';

class InterviewChatLoadedBody extends StatelessWidget {
  const InterviewChatLoadedBody({
    super.key,
    required this.state,
    required this.currentUid,
    required this.onRespondToProposal,
  });

  final InterviewSessionLoaded state;
  final String? currentUid;
  final void Function(String proposalId, bool accept) onRespondToProposal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.interview.meetingLink case final meetingLink?) ...[
          InterviewMeetingBanner(meetingLink: meetingLink),
          const SizedBox(height: uiSpacing8),
        ],
        Expanded(
          child: InterviewMessagesList(
            messages: state.messages,
            currentUid: currentUid,
            onRespondToProposal: onRespondToProposal,
          ),
        ),
      ],
    );
  }
}
