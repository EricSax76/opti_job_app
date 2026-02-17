import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

class InterviewChatPageController {
  const InterviewChatPageController._();

  static InterviewSessionCubit createSessionCubit({
    required BuildContext context,
    required String interviewId,
  }) {
    return InterviewSessionCubit(
      repository: context.read<InterviewRepository>(),
      interviewId: interviewId,
    )
      ..start()
      ..markAsSeen();
  }
}
