import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';

enum InterviewChatSessionViewStatus { loading, error, ready }

class InterviewChatSessionViewModel extends Equatable {
  const InterviewChatSessionViewModel({
    required this.status,
    this.loadedState,
    this.errorMessage,
  });

  final InterviewChatSessionViewStatus status;
  final InterviewSessionLoaded? loadedState;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, loadedState, errorMessage];
}
