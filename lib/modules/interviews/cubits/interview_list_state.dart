part of 'interview_list_cubit.dart';

abstract class InterviewListState extends Equatable {
  const InterviewListState();

  @override
  List<Object> get props => [];
}

class InterviewListInitial extends InterviewListState {}

class InterviewListLoading extends InterviewListState {}

class InterviewListLoaded extends InterviewListState {
  final List<Interview> interviews;

  const InterviewListLoaded(this.interviews);

  @override
  List<Object> get props => [interviews];
}

class InterviewListEmpty extends InterviewListState {}

class InterviewListError extends InterviewListState {
  final String message;

  const InterviewListError(this.message);

  @override
  List<Object> get props => [message];
}
