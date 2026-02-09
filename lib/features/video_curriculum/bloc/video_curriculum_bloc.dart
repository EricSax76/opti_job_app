import 'package:bloc/bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:equatable/equatable.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';

part 'video_curriculum_event.dart';
part 'video_curriculum_state.dart';

typedef VideoCurriculumCandidateUidProvider = String? Function();

class VideoCurriculumBloc
    extends Bloc<VideoCurriculumEvent, VideoCurriculumState> {
  VideoCurriculumBloc({
    required VideoCurriculumRepository videoCurriculumRepository,
    required VideoCurriculumCandidateUidProvider candidateUidProvider,
  }) : _videoCurriculumRepository = videoCurriculumRepository,
       _candidateUidProvider = candidateUidProvider,
       super(const VideoCurriculumState()) {
    on<VideoRecordingStarted>(_onVideoRecordingStarted);
    on<VideoRecordingStopped>(_onVideoRecordingStopped);
    on<RetryVideoRecording>(_onRetryVideoRecording);
    on<SaveVideoCurriculumRequested>(_onSaveVideoCurriculumRequested);
  }

  final VideoCurriculumRepository _videoCurriculumRepository;
  final VideoCurriculumCandidateUidProvider _candidateUidProvider;

  void _onVideoRecordingStarted(
    VideoRecordingStarted event,
    Emitter<VideoCurriculumState> emit,
  ) {
    if (state.attemptsLeft > 0) {
      emit(
        state.copyWith(
          status: VideoCurriculumStatus.recording,
          error: () => null,
        ),
      );
    }
  }

  void _onVideoRecordingStopped(
    VideoRecordingStopped event,
    Emitter<VideoCurriculumState> emit,
  ) {
    final nextAttempts = state.attemptsLeft > 0 ? state.attemptsLeft - 1 : 0;
    emit(
      state.copyWith(
        status: VideoCurriculumStatus.success,
        recordedVideoPath: event.path,
        attemptsLeft: nextAttempts,
        error: () => null,
      ),
    );
  }

  void _onRetryVideoRecording(
    RetryVideoRecording event,
    Emitter<VideoCurriculumState> emit,
  ) {
    if (state.attemptsLeft > 0) {
      emit(
        state.copyWith(
          status: VideoCurriculumStatus.initial,
          recordedVideoPath: null,
          error: () => null,
        ),
      );
    }
  }

  Future<void> _onSaveVideoCurriculumRequested(
    SaveVideoCurriculumRequested event,
    Emitter<VideoCurriculumState> emit,
  ) async {
    final recordedVideoPath = state.recordedVideoPath;
    if (recordedVideoPath == null || recordedVideoPath.trim().isEmpty) {
      emit(
        state.copyWith(
          status: VideoCurriculumStatus.failure,
          error: () => 'Primero debes grabar un vídeo.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: VideoCurriculumStatus.uploading,
        error: () => null,
      ),
    );
    try {
      final uid = _candidateUidProvider();
      if (uid == null) {
        emit(
          state.copyWith(
            status: VideoCurriculumStatus.failure,
            error: () => 'Debes iniciar sesión para guardar.',
          ),
        );
        return;
      }

      await _videoCurriculumRepository.uploadVideoCurriculum(
        candidateUid: uid,
        filePath: recordedVideoPath,
      );

      emit(
        state.copyWith(
          status: VideoCurriculumStatus.success,
          error: () => null,
        ),
      );
    } on FirebaseException catch (error) {
      emit(
        state.copyWith(
          status: VideoCurriculumStatus.failure,
          error: () => error.message ?? 'No se pudo guardar tu vídeo.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VideoCurriculumStatus.failure,
          error: () => e.toString(),
        ),
      );
    }
  }
}
