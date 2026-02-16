import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_chat_actions_controller.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_session_body.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_view.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_message_input_area.dart';

class InterviewChatContainer extends StatefulWidget {
  const InterviewChatContainer({super.key});

  @override
  State<InterviewChatContainer> createState() => _InterviewChatContainerState();
}

class _InterviewChatContainerState extends State<InterviewChatContainer> {
  late final InterviewChatActionsController _actions;

  @override
  void initState() {
    super.initState();
    _actions = InterviewChatActionsController(
      sessionCubit: context.read<InterviewSessionCubit>(),
    );
  }

  @override
  void dispose() {
    _actions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InterviewSessionCubit, InterviewSessionState>(
      listenWhen: (_, current) => current is InterviewSessionActionError,
      listener: _handleActionError,
      child: InterviewChatView(
        body: InterviewChatSessionBody(
          onRespondToProposal: _actions.respondToProposal,
        ),
        inputArea: InterviewMessageInputArea(
          controller: _actions.messageController,
          onSend: _actions.sendMessage,
          onProposeSlot: () => _actions.proposeSlot(context),
          onStartMeeting: () => _actions.startMeeting(context),
        ),
      ),
    );
  }

  void _handleActionError(BuildContext context, InterviewSessionState state) {
    if (state is! InterviewSessionActionError) return;
    final message = state.error.trim();
    if (message.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
