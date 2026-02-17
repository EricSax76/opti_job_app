import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/logic/candidate_dashboard_screen_logic.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

class CandidateInterviewsBadge extends StatelessWidget {
  const CandidateInterviewsBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final candidateUid = context.select(
      (CandidateAuthCubit cubit) => cubit.state.candidate?.uid,
    );

    return BlocBuilder<InterviewListCubit, InterviewListState>(
      builder: (context, state) {
        final unread = CandidateDashboardScreenLogic.unreadInterviewCount(
          state: state,
          candidateUid: candidateUid,
        );

        if (unread == 0) return child;

        return Badge(
          label: Text(
            '$unread',
            style: const TextStyle(fontSize: uiSpacing8 + 2),
          ),
          child: child,
        );
      },
    );
  }
}
