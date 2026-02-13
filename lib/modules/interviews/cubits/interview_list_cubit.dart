import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

part 'interview_list_state.dart';

class InterviewListCubit extends Cubit<InterviewListState> {
  final InterviewRepository _repository;
  final String _uid;
  StreamSubscription<List<Interview>>? _subscription;

  InterviewListCubit({
    required InterviewRepository repository,
    required String uid,
  })  : _repository = repository,
        _uid = uid,
        super(InterviewListInitial()) {
    _subscribe();
  }

  void _subscribe() {
    emit(InterviewListLoading());
    _subscription = _repository.interviewsStream(_uid).listen(
      (interviews) {
        if (interviews.isEmpty) {
          emit(InterviewListEmpty());
        } else {
          emit(InterviewListLoaded(interviews));
        }
      },
      onError: (error) {
        emit(InterviewListError(error.toString()));
      },
    );
  }

  Future<void> refresh() async {
    // Re-subscription logic if needed, or just let stream handle updates
    // For manual refresh in stream-based arch, usually not needed unless connection lost
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
