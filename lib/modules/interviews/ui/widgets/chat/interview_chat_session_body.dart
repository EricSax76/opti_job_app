import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_session_logic.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_chat_session_view_model.dart';
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
        final viewModel = InterviewChatSessionLogic.buildViewModel(state);
        return _buildFromViewModel(viewModel);
      },
    );
  }

  Widget _buildFromViewModel(InterviewChatSessionViewModel viewModel) {
    switch (viewModel.status) {
      case InterviewChatSessionViewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case InterviewChatSessionViewStatus.error:
        final message = viewModel.errorMessage ?? 'No se pudo cargar la sesión';
        return Center(child: Text('Error: $message'));
      case InterviewChatSessionViewStatus.ready:
        final loadedState = viewModel.loadedState;
        if (loadedState == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return InterviewChatLoadedBody(
          state: loadedState,
          currentUid: currentUid,
          onRespondToProposal: onRespondToProposal,
        );
    }
  }
}
