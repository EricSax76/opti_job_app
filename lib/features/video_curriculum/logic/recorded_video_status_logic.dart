import 'package:opti_job_app/features/video_curriculum/view/models/recorded_video_status_view_model.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/video_curriculum_playback_helpers.dart';

class RecordedVideoStatusLogic {
  const RecordedVideoStatusLogic._();

  static RecordedVideoStatusViewModel buildViewModel(String? recordedPath) {
    final safePath = _normalizePath(recordedPath);
    final hasRecordedVideo = safePath != null;
    final playbackUri = hasRecordedVideo ? buildLocalVideoUri(safePath) : null;
    final fileName = hasRecordedVideo ? safePath.split('/').last : null;

    return RecordedVideoStatusViewModel(
      hasRecordedVideo: hasRecordedVideo,
      title: hasRecordedVideo
          ? 'Vídeo grabado (local)'
          : 'Aún no grabaste un vídeo',
      description: hasRecordedVideo
          ? (fileName ?? safePath)
          : 'Pulsa el botón rojo para empezar a grabar.',
      playbackUri: playbackUri,
    );
  }

  static String? _normalizePath(String? path) {
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
