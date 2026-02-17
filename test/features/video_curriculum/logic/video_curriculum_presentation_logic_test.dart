import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/logic/recorded_video_status_logic.dart';
import 'package:opti_job_app/features/video_curriculum/logic/uploaded_video_status_logic.dart';
import 'package:opti_job_app/features/video_curriculum/logic/video_camera_logic.dart';
import 'package:opti_job_app/features/video_curriculum/logic/video_curriculum_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

void main() {
  group('VideoCurriculumLogic', () {
    test('buildViewModel detects recorded video from trimmed path', () {
      const state = VideoCurriculumState(recordedVideoPath: ' /tmp/video.mp4 ');

      final viewModel = VideoCurriculumLogic.buildViewModel(state);

      expect(viewModel.hasRecordedVideo, isTrue);
      expect(VideoCurriculumLogic.hasRecordedVideo('   '), isFalse);
    });

    test('shouldRebuildContent only when recorded path changes', () {
      const previous = VideoCurriculumState(recordedVideoPath: 'a.mp4');
      const same = VideoCurriculumState(recordedVideoPath: 'a.mp4');
      const changed = VideoCurriculumState(recordedVideoPath: 'b.mp4');

      expect(
        VideoCurriculumLogic.shouldRebuildContent(previous, same),
        isFalse,
      );
      expect(
        VideoCurriculumLogic.shouldRebuildContent(previous, changed),
        isTrue,
      );
    });
  });

  group('RecordedVideoStatusLogic', () {
    test('buildViewModel exposes playback data when path is valid', () {
      final viewModel = RecordedVideoStatusLogic.buildViewModel(
        '/tmp/video_final.mp4',
      );

      expect(viewModel.hasRecordedVideo, isTrue);
      expect(viewModel.canPlay, isTrue);
      expect(viewModel.description, 'video_final.mp4');
    });

    test('buildViewModel returns empty-state copy when no path', () {
      final viewModel = RecordedVideoStatusLogic.buildViewModel('  ');

      expect(viewModel.hasRecordedVideo, isFalse);
      expect(viewModel.canPlay, isFalse);
      expect(viewModel.title, 'Aún no grabaste un vídeo');
    });
  });

  group('UploadedVideoStatusLogic', () {
    test('buildViewModel maps uploaded candidate video', () {
      const video = CandidateVideoCurriculum(
        storagePath: ' videos/candidate.mp4 ',
        contentType: 'video/mp4',
        sizeBytes: 12345,
      );

      final viewModel = UploadedVideoStatusLogic.buildViewModel(video);

      expect(viewModel.hasUploadedVideo, isTrue);
      expect(viewModel.storagePath, 'videos/candidate.mp4');
      expect(viewModel.description, startsWith('Tamaño: '));
    });

    test('buildViewModel maps empty uploaded state', () {
      final viewModel = UploadedVideoStatusLogic.buildViewModel(null);

      expect(viewModel.hasUploadedVideo, isFalse);
      expect(viewModel.storagePath, isEmpty);
    });

    test('parseDownloadUri returns null for blank urls', () {
      expect(UploadedVideoStatusLogic.parseDownloadUri('  '), isNull);
      expect(
        UploadedVideoStatusLogic.parseDownloadUri(
          'https://example.com/video.mp4',
        ),
        isA<Uri>(),
      );
    });
  });

  group('VideoCameraLogic', () {
    test('shouldDisposeCamera for inactive and paused states', () {
      expect(
        VideoCameraLogic.shouldDisposeCamera(AppLifecycleState.inactive),
        isTrue,
      );
      expect(
        VideoCameraLogic.shouldDisposeCamera(AppLifecycleState.paused),
        isTrue,
      );
      expect(
        VideoCameraLogic.shouldDisposeCamera(AppLifecycleState.resumed),
        isFalse,
      );
    });

    test('shouldInitializeOnResume and attempts helpers', () {
      expect(
        VideoCameraLogic.shouldInitializeOnResume(
          hasRecordedVideo: false,
          isCameraReady: false,
        ),
        isTrue,
      );
      expect(
        VideoCameraLogic.shouldInitializeOnResume(
          hasRecordedVideo: true,
          isCameraReady: false,
        ),
        isFalse,
      );
      expect(VideoCameraLogic.hasAttemptsLeft(1), isTrue);
      expect(VideoCameraLogic.hasAttemptsLeft(0), isFalse);
    });
  });
}
