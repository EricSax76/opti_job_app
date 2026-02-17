import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_logic.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_chat_session_view_model.dart';

class InterviewChatSessionLogic {
  const InterviewChatSessionLogic._();

  static InterviewChatSessionViewModel buildViewModel(
    InterviewSessionState state,
  ) {
    if (state is InterviewSessionLoading || state is InterviewSessionInitial) {
      return const InterviewChatSessionViewModel(
        status: InterviewChatSessionViewStatus.loading,
      );
    }

    if (state is InterviewSessionError) {
      return InterviewChatSessionViewModel(
        status: InterviewChatSessionViewStatus.error,
        errorMessage: state.message,
      );
    }

    final loadedState = InterviewChatLogic.resolveLoadedState(state);
    if (loadedState == null) {
      return const InterviewChatSessionViewModel(
        status: InterviewChatSessionViewStatus.loading,
      );
    }

    return InterviewChatSessionViewModel(
      status: InterviewChatSessionViewStatus.ready,
      loadedState: loadedState,
    );
  }
}
