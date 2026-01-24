import 'package:flutter/foundation.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/services/curriculum_service.dart';

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

  Future<Curriculum> uploadAttachment({
    required String candidateUid,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) {
    return _service.uploadAttachment(
      candidateUid: candidateUid,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  Future<Curriculum> deleteAttachment({
    required String candidateUid,
    required CurriculumAttachment attachment,
  }) {
    return _service.deleteAttachment(
      candidateUid: candidateUid,
      attachment: attachment,
    );
  }

  Future<String> getAttachmentUrl({
    required CurriculumAttachment attachment,
  }) {
    return _service.getAttachmentUrl(attachment);
  }

  String mapException(Object error) {
    if (error is Exception && error.toString().contains('permission-denied')) {
      return 'Permiso denegado al acceder a los datos.';
    }
    return error.toString();
  }
}
