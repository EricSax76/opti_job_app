import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
  }) : _repository = repository,
       _interviewId = interviewId,
       super(InterviewSessionInitial());

  Interview? _latestInterview;
  List<InterviewMessage> _latestMessages = const [];

  void _updateState() {
    final interview = _latestInterview;
    if (interview == null) return;
    emit(
      InterviewSessionLoaded(interview: interview, messages: _latestMessages),
    );
  }

  Future<void> start() async {
    if (_interviewSubscription != null) return;
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
      onError: (error) =>
          emit(InterviewSessionError(_normalizeErrorMessage(error))),
    );

    _messagesSubscription = _repository.messagesStream(_interviewId).listen((
      messages,
    ) {
      _latestMessages = messages;
      _updateState();
    }, onError: _emitActionError);
  }

  Future<void> refresh() async {
    await _interviewSubscription?.cancel();
    await _messagesSubscription?.cancel();
    _interviewSubscription = null;
    _messagesSubscription = null;
    await start();
  }

  void retry() => unawaited(refresh());

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
    await _runAction(() {
      return _repository.sendMessage(
        interviewId: _interviewId,
        content: content,
      );
    });
  }

  Future<void> proposeSlot(DateTime date, String timeZone) async {
    await _runAction(() {
      return _repository.proposeSlot(
        interviewId: _interviewId,
        proposedAt: date,
        timeZone: timeZone,
      );
    });
  }

  Future<void> respondToSlot(String proposalId, bool accept) async {
    await _runAction(() {
      return _repository.respondToSlot(
        interviewId: _interviewId,
        proposalId: proposalId,
        accept: accept,
      );
    });
  }

  Future<void> startMeeting(String link) async {
    if (link.trim().isEmpty) return;
    await _runAction(() {
      return _repository.startMeeting(
        interviewId: _interviewId,
        meetingLink: link,
      );
    });
  }

  Future<void> cancelInterview({String? reason}) async {
    await _runAction(() {
      return _repository.cancelInterview(_interviewId, reason: reason);
    });
  }

  Future<void> completeInterview({String? notes}) async {
    await _runAction(() {
      return _repository.completeInterview(_interviewId, notes: notes);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      _emitActionError(error);
    }
  }

  void _emitActionError(Object error) {
    emit(
      InterviewSessionActionError(
        _resolveLoadedStateSnapshot(),
        _normalizeErrorMessage(error),
      ),
    );
  }

  InterviewSessionLoaded? _resolveLoadedStateSnapshot() {
    if (state is InterviewSessionLoaded) {
      return state as InterviewSessionLoaded;
    }
    final interview = _latestInterview;
    if (interview == null) return null;

    return InterviewSessionLoaded(
      interview: interview,
      messages: _latestMessages,
    );
  }

  String _normalizeErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'No se pudo completar la acción.';
    }
    return message;
  }

  @override
  Future<void> close() {
    _interviewSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
