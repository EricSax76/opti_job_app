import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_service.dart';

class CurriculumRepository {
  CurriculumRepository(this._service);

  final CurriculumService _service;

  Future<Curriculum> fetchCurriculum(String candidateUid) {
    return _service.fetchCurriculum(candidateUid);
  }

  Future<Curriculum> saveCurriculum({
    required String candidateUid,
    required Curriculum curriculum,
  }) {
    return _service.saveCurriculum(
      candidateUid: candidateUid,
      curriculum: curriculum,
    );
  }
}

