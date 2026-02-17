import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_chat_page_controller.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_container.dart';

class InterviewChatPage extends StatelessWidget {
  const InterviewChatPage({super.key, required this.interviewId});

  final String interviewId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InterviewChatPageController.createSessionCubit(
        context: context,
        interviewId: interviewId,
      ),
      child: const InterviewChatContainer(),
    );
  }
}
