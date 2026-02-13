part of 'interview_session_cubit.dart';

abstract class InterviewSessionState extends Equatable {
  const InterviewSessionState();

  @override
  List<Object?> get props => [];
}

class InterviewSessionInitial extends InterviewSessionState {}

class InterviewSessionLoading extends InterviewSessionState {}

class InterviewSessionLoaded extends InterviewSessionState {
  final Interview interview;
  final List<InterviewMessage> messages;

  const InterviewSessionLoaded({
    required this.interview,
    required this.messages,
  });

  InterviewSessionLoaded copyWith({
    Interview? interview,
    List<InterviewMessage>? messages,
  }) {
    return InterviewSessionLoaded(
      interview: interview ?? this.interview,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [interview, messages];
}

class InterviewSessionError extends InterviewSessionState {
  final String message;

  const InterviewSessionError(this.message);

  @override
  List<Object?> get props => [message];
}

class InterviewSessionActionError extends InterviewSessionState {
  final InterviewSessionLoaded? previousState; // Keep previous data visible
  final String error;

  const InterviewSessionActionError(this.previousState, this.error);
  
  @override
  List<Object?> get props => [previousState, error];
}
