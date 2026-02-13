import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

part 'interview_session_state.dart';

class InterviewSessionCubit extends Cubit<InterviewSessionState> {
  final InterviewRepository _repository;
  final String _interviewId;
  StreamSubscription<Interview?>? _interviewSubscription;
  StreamSubscription<List<InterviewMessage>>? _messagesSubscription;

  InterviewSessionCubit({
    required InterviewRepository repository,
    required String interviewId,
  })  : _repository = repository,
        _interviewId = interviewId,
        super(InterviewSessionInitial()) {
    _subscribeManual();
  }

  Interview? _latestInterview;
  List<InterviewMessage> _latestMessages = const [];

  void _updateState() {
    final interview = _latestInterview;
    if (interview == null) return;
    emit(
      InterviewSessionLoaded(
        interview: interview,
        messages: _latestMessages,
      ),
    );
  }

  void _subscribeManual() {
    emit(InterviewSessionLoading());

    _interviewSubscription = _repository.interviewStream(_interviewId).listen(
      (interview) {
        if (interview == null) {
          emit(const InterviewSessionError('Interview not found'));
          return;
        }
        _latestInterview = interview;
        _updateState();
      },
      onError: (e) => emit(InterviewSessionError(e.toString())),
    );

    _messagesSubscription = _repository.messagesStream(_interviewId).listen(
      (messages) {
        _latestMessages = messages;
        _updateState();
      },
      onError: (e) {
        final previousState = state is InterviewSessionLoaded
            ? state as InterviewSessionLoaded
            : (_latestInterview == null
                  ? null
                  : InterviewSessionLoaded(
                      interview: _latestInterview!,
                      messages: _latestMessages,
                    ));
        emit(InterviewSessionActionError(previousState, e.toString()));
      },
    );
  }

  Future<void> markAsSeen() async {
    try {
      await _repository.markAsSeen(_interviewId);
    } catch (e) {
      // creating specific error state or just logging?
      // Silent failure usually ok for read receipts
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    try {
      await _repository.sendMessage(
        interviewId: _interviewId,
        content: content,
      );
    } catch (e) {
      emit(InterviewSessionActionError(
        (state is InterviewSessionLoaded)
            ? (state as InterviewSessionLoaded)
            : null,
        e.toString(),
      ));
    }
  }

  Future<void> proposeSlot(DateTime date, String timeZone) async {
    try {
      await _repository.proposeSlot(
        interviewId: _interviewId,
        proposedAt: date,
        timeZone: timeZone,
      );
    } catch (e) {
      emit(InterviewSessionActionError(
        (state is InterviewSessionLoaded)
            ? (state as InterviewSessionLoaded)
            : null,
        e.toString(),
      ));
    }
  }

  Future<void> respondToSlot(String proposalId, bool accept) async {
    try {
      await _repository.respondToSlot(
        interviewId: _interviewId,
        proposalId: proposalId,
        accept: accept,
      );
    } catch (e) {
      emit(InterviewSessionActionError(
        (state is InterviewSessionLoaded)
            ? (state as InterviewSessionLoaded)
            : null,
        e.toString(),
      ));
    }
  }

  Future<void> startMeeting(String link) async {
    try {
      await _repository.startMeeting(
        interviewId: _interviewId,
        meetingLink: link,
      );
    } catch (e) {
      emit(InterviewSessionActionError(
        (state is InterviewSessionLoaded)
            ? (state as InterviewSessionLoaded)
            : null,
        e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _interviewSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
