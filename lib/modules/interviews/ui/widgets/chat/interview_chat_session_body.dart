import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/widgets/chat/interview_chat_loaded_body.dart';

class InterviewChatSessionBody extends StatelessWidget {
  const InterviewChatSessionBody({
    super.key,
    required this.currentUid,
    required this.onRespondToProposal,
  });

  final String? currentUid;
  final void Function(String proposalId, bool accept) onRespondToProposal;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InterviewSessionCubit, InterviewSessionState>(
      builder: (context, state) {
        if (state is InterviewSessionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is InterviewSessionError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        final loadedState = _resolveLoadedState(state);
        if (loadedState == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return InterviewChatLoadedBody(
          state: loadedState,
          currentUid: currentUid,
          onRespondToProposal: onRespondToProposal,
        );
      },
    );
  }

  InterviewSessionLoaded? _resolveLoadedState(InterviewSessionState state) {
    if (state is InterviewSessionLoaded) {
      return state;
    }
    if (state is InterviewSessionActionError) {
      return state.previousState;
    }
    return null;
  }
}
