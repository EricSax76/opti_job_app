import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_container.dart';

class InterviewChatPage extends StatelessWidget {
  const InterviewChatPage({
    super.key,
    required this.cubit,
  });

  final InterviewSessionCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: const InterviewChatContainer(),
    );
  }
}
