import 'package:opti_job_app/features/video_curriculum/services/video_curriculum_service.dart';

class VideoCurriculumRepository {
  VideoCurriculumRepository(this._service);

  final VideoCurriculumService _service;

  Future<void> uploadVideoCurriculum({
    required String candidateUid,
    required String filePath,
  }) {
    return _service.uploadVideoCurriculum(
      candidateUid: candidateUid,
      filePath: filePath,
    );
  }
}
