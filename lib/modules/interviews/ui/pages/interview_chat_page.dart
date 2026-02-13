import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_view.dart';

class InterviewChatPage extends StatelessWidget {
  const InterviewChatPage({super.key, required this.interviewId});

  final String interviewId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InterviewSessionCubit(
        repository: context.read<InterviewRepository>(),
        interviewId: interviewId,
      )..markAsSeen(),
      child: const InterviewChatView(),
    );
  }
}
