import 'package:opti_job_app/modules/compliance/models/audit_log.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';

abstract class AuditRepository {
  Future<void> logAction(AuditLog log);
  Stream<List<AuditLog>> getLogs({String? actorUid, String? targetId, String? companyId});
}

abstract class DataRequestRepository {
  Future<DataRequest> submitRequest(DataRequest request);
  Stream<List<DataRequest>> getRequests(String candidateUid);
  Stream<List<DataRequest>> getAllRequests(); // For Admins
  Future<void> updateRequestStatus(String requestId, DataRequestStatus status, {String? response, String? processedBy});
}

abstract class ConsentRepository {
  Future<ConsentRecord> saveConsent(ConsentRecord record);
  Future<ConsentRecord?> getConsent(String candidateUid, String companyId, String type);
  Stream<List<ConsentRecord>> getConsents(String candidateUid);
}
