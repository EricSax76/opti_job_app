import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';

class ConsentService {
  ConsentService(this._repository);

  final ConsentRepository _repository;

  Future<ConsentRecord> grantConsent({
    required String candidateUid,
    required String companyId,
    required String type,
    LegalBasis basis = LegalBasis.consent,
  }) async {
    final record = ConsentRecord(
      id: '',
      candidateUid: candidateUid,
      companyId: companyId,
      type: type,
      granted: true,
      legalBasis: basis,
    );
    return _repository.saveConsent(record);
  }

  Future<bool> checkConsent(String candidateUid, String companyId, String type) async {
    final consent = await _repository.getConsent(candidateUid, companyId, type);
    if (consent == null) return false;
    if (!consent.granted) return false;
    if (consent.expiresAt != null && consent.expiresAt!.isBefore(DateTime.now())) return false;
    return true;
  }
}
