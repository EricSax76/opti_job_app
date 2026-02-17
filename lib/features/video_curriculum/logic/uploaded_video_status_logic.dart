import 'package:opti_job_app/features/video_curriculum/view/models/uploaded_video_status_view_model.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/video_curriculum_playback_helpers.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

class UploadedVideoStatusLogic {
  const UploadedVideoStatusLogic._();

  static UploadedVideoStatusViewModel buildViewModel(
    CandidateVideoCurriculum? video,
  ) {
    final storagePath = _normalizeText(video?.storagePath) ?? '';
    final hasUploadedVideo = storagePath.isNotEmpty && video != null;

    if (!hasUploadedVideo) {
      return const UploadedVideoStatusViewModel(
        hasUploadedVideo: false,
        title: 'Sin videocurrículum subido',
        description:
            'Graba y guarda un vídeo para que quede asociado a tu perfil.',
        storagePath: '',
      );
    }

    return UploadedVideoStatusViewModel(
      hasUploadedVideo: true,
      title: 'Videocurrículum subido',
      description: 'Tamaño: ${formatBytes(video.sizeBytes)}',
      storagePath: storagePath,
      sizeLabel: formatBytes(video.sizeBytes),
    );
  }

  static String resolveStoragePath(CandidateVideoCurriculum? video) {
    return _normalizeText(video?.storagePath) ?? '';
  }

  static Uri? parseDownloadUri(String? downloadUrl) {
    final normalizedUrl = _normalizeText(downloadUrl);
    if (normalizedUrl == null) return null;
    return Uri.tryParse(normalizedUrl);
  }

  static String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
