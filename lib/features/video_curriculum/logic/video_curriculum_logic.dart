import 'package:opti_job_app/features/video_curriculum/bloc/video_curriculum_bloc.dart';
import 'package:opti_job_app/features/video_curriculum/view/models/video_curriculum_view_model.dart';

class VideoCurriculumLogic {
  const VideoCurriculumLogic._();

  static bool shouldRebuildContent(
    VideoCurriculumState previous,
    VideoCurriculumState current,
  ) {
    return previous.recordedVideoPath != current.recordedVideoPath;
  }

  static VideoCurriculumViewModel buildViewModel(VideoCurriculumState state) {
    return VideoCurriculumViewModel(
      hasRecordedVideo: hasRecordedVideo(state.recordedVideoPath),
    );
  }

  static bool hasRecordedVideo(String? recordedVideoPath) {
    return _normalizePath(recordedVideoPath) != null;
  }

  static String? _normalizePath(String? path) {
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
