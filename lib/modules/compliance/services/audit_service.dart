import 'package:opti_job_app/modules/compliance/models/audit_log.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';

class AuditService {
  AuditService(this._repository);

  final AuditRepository _repository;

  Future<void> log({
    required String action,
    required String actorUid,
    required String actorRole,
    required String targetType,
    required String targetId,
    String? companyId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final log = AuditLog(
      id: '',
      action: action,
      actorUid: actorUid,
      actorRole: actorRole,
      targetType: targetType,
      targetId: targetId,
      companyId: companyId,
      metadata: metadata,
    );
    await _repository.logAction(log);
  }
}
