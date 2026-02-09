import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/repositories/video_curriculum_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockVideoCurriculumRepository extends Mock
    implements VideoCurriculumRepository {}

void main() {
  group('Video recording flow', () {
    test('decrements attempts on stop and clears path on retry', () async {
      final bloc = VideoCurriculumBloc(
        videoCurriculumRepository: _MockVideoCurriculumRepository(),
        candidateUidProvider: () => 'uid',
      );

      bloc.add(VideoRecordingStarted());
      await _waitForState(
        bloc,
        (state) => state.status == VideoCurriculumStatus.recording,
      );

      bloc.add(const VideoRecordingStopped('/tmp/video.mp4'));
      await _waitForState(
        bloc,
        (state) =>
            state.status == VideoCurriculumStatus.success &&
            state.recordedVideoPath == '/tmp/video.mp4' &&
            state.attemptsLeft == 2,
      );

      bloc.add(RetryVideoRecording());
      await _waitForState(
        bloc,
        (state) =>
            state.status == VideoCurriculumStatus.initial &&
            state.recordedVideoPath == null &&
            state.attemptsLeft == 2,
      );

      await bloc.close();
    });

    test('never decrements attempts below zero', () async {
      final bloc = VideoCurriculumBloc(
        videoCurriculumRepository: _MockVideoCurriculumRepository(),
        candidateUidProvider: () => 'uid',
      );

      bloc.add(const VideoRecordingStopped('/tmp/video1.mp4'));
      await _waitForState(bloc, (state) => state.attemptsLeft == 2);
      bloc.add(const VideoRecordingStopped('/tmp/video2.mp4'));
      await _waitForState(bloc, (state) => state.attemptsLeft == 1);
      bloc.add(const VideoRecordingStopped('/tmp/video3.mp4'));
      await _waitForState(bloc, (state) => state.attemptsLeft == 0);
      bloc.add(const VideoRecordingStopped('/tmp/video4.mp4'));
      await _waitForState(bloc, (state) => state.attemptsLeft == 0);

      expect(bloc.state.attemptsLeft, 0);
      await bloc.close();
    });
  });

  group('SaveVideoCurriculumRequested', () {
    test('fails when no video has been recorded', () async {
      final bloc = VideoCurriculumBloc(
        videoCurriculumRepository: _MockVideoCurriculumRepository(),
        candidateUidProvider: () => 'uid',
      );

      bloc.add(const SaveVideoCurriculumRequested());
      await _waitForState(
        bloc,
        (state) => state.status == VideoCurriculumStatus.failure,
      );

      expect(bloc.state.error, 'Primero debes grabar un vídeo.');
      await bloc.close();
    });

    test('fails when candidate is not authenticated', () async {
      final bloc = VideoCurriculumBloc(
        videoCurriculumRepository: _MockVideoCurriculumRepository(),
        candidateUidProvider: () => null,
      );

      bloc.add(const VideoRecordingStopped('/tmp/video.mp4'));
      await _waitForState(
        bloc,
        (state) => state.recordedVideoPath == '/tmp/video.mp4',
      );

      bloc.add(const SaveVideoCurriculumRequested());
      await _waitForState(
        bloc,
        (state) => state.status == VideoCurriculumStatus.failure,
      );

      expect(bloc.state.error, 'Debes iniciar sesión para guardar.');
      await bloc.close();
    });
  });
}

Future<VideoCurriculumState> _waitForState(
  VideoCurriculumBloc bloc,
  bool Function(VideoCurriculumState state) matcher,
) async {
  if (matcher(bloc.state)) {
    return bloc.state;
  }
  return bloc.stream.firstWhere(matcher);
}
