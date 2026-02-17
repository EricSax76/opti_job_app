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
  }) : _repository = repository,
       _uid = uid,
       super(InterviewListInitial());

  Future<void> start() async {
    if (_subscription != null) return;
    emit(InterviewListLoading());
    _subscription = _repository
        .interviewsStream(_uid)
        .listen(
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
    await _subscription?.cancel();
    _subscription = null;
    await start();
  }

  void retry() => unawaited(refresh());


  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
