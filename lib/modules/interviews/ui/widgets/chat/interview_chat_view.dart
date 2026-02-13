import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_chat_actions_controller.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_session_body.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_message_input_area.dart';

class InterviewChatView extends StatefulWidget {
  const InterviewChatView({super.key});

  @override
  State<InterviewChatView> createState() => _InterviewChatViewState();
}

class _InterviewChatViewState extends State<InterviewChatView> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Entrevista')),
      body: BlocListener<InterviewSessionCubit, InterviewSessionState>(
        listenWhen: (_, current) => current is InterviewSessionActionError,
        listener: (context, state) {
          if (state is! InterviewSessionActionError) return;
          final message = state.error.trim();
          if (message.isEmpty) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(child: InterviewChatSessionBody()),
            InterviewMessageInputArea(
              controller: _actions.messageController,
              onSend: _actions.sendMessage,
              onProposeSlot: () => _actions.proposeSlot(context),
              onStartMeeting: () => _actions.startMeeting(context),
            ),
          ],
        ),
      ),
    );
  }
}
