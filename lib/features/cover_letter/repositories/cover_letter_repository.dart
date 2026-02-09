import 'package:opti_job_app/features/cover_letter/services/cover_letter_service.dart';

class CoverLetterRepository {
  CoverLetterRepository(this._service);

  final CoverLetterService _service;

  Future<String?> fetchCoverLetterText(String candidateUid) {
    return _service.fetchCoverLetterText(candidateUid);
  }

  Future<void> saveCoverLetterText({
    required String candidateUid,
    required String text,
  }) {
    return _service.saveCoverLetterText(candidateUid: candidateUid, text: text);
  }
}
