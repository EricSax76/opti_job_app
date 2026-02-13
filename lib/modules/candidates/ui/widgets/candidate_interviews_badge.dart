import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';

class CandidateInterviewsBadge extends StatelessWidget {
  const CandidateInterviewsBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InterviewListCubit, InterviewListState>(
      builder: (context, state) {
        int unread = 0;
        if (state is InterviewListLoaded) {
          final uid = context.read<CandidateAuthCubit>().state.candidate?.uid;
          if (uid != null) {
            for (final interview in state.interviews) {
              unread += (interview.unreadCounts?[uid] ?? 0);
            }
          }
        }

        if (unread == 0) return child;

        return Badge(
          label: Text('$unread', style: const TextStyle(fontSize: 10)),
          child: child,
        );
      },
    );
  }
}
