import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/core/utils/callable_with_fallback.dart';
import 'package:opti_job_app/modules/compliance/models/audit_log.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';

class FirebaseComplianceRepository
    implements
        AuditRepository,
        DataRequestRepository,
        ConsentRepository,
        SalaryBenchmarkRepository {
  FirebaseComplianceRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _callables = CallableWithFallback(
         functions:
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
         fallbackFunctions: fallbackFunctions ?? FirebaseFunctions.instance,
       );

  final FirebaseFirestore _firestore;
  final CallableWithFallback _callables;

  // --- Audit ---
  @override
  Future<void> logAction(AuditLog log) async {
    await _firestore.collection('auditLogs').add({
      ...log.toJson(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AuditLog>> getLogs({
    String? actorUid,
    String? targetId,
    String? companyId,
  }) {
    Query query = _firestore.collection('auditLogs');
    if (actorUid != null) query = query.where('actorUid', isEqualTo: actorUid);
    if (targetId != null) query = query.where('targetId', isEqualTo: targetId);
    if (companyId != null) {
      query = query.where('companyId', isEqualTo: companyId);
    }

    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => AuditLog.fromJson(
                  d.data() as Map<String, dynamic>,
                  id: d.id,
                ),
              )
              .toList(),
        );
  }

  // --- Data Requests ---
  @override
  Future<DataRequest> submitRequest(DataRequest request) async {
    final payload = await _callCallableWithFallback(
      name: 'submitDataRequest',
      payload: {
        'type': request.type.name,
        'description': request.description,
        if (request.companyId != null) 'companyId': request.companyId,
        if (request.applicationId != null)
          'applicationId': request.applicationId,
        if (request.metadata.isNotEmpty) 'metadata': request.metadata,
      },
    );
    final id = payload['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      throw StateError('submitDataRequest did not return a valid id.');
    }

    final doc = await _firestore.collection('dataRequests').doc(id).get();
    final data = doc.data() ?? request.toJson();
    return DataRequest.fromJson(data, id: id);
  }

  @override
  Stream<List<DataRequest>> getRequests(String candidateUid) {
    return _firestore
        .collection('dataRequests')
        .where('candidateUid', isEqualTo: candidateUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => DataRequest.fromJson(d.data(), id: d.id))
              .toList(),
        );
  }

  @override
  Stream<List<DataRequest>> getAllRequests() {
    return _firestore
        .collection('dataRequests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => DataRequest.fromJson(d.data(), id: d.id))
              .toList(),
        );
  }

  @override
  Future<void> updateRequestStatus(
    String requestId,
    DataRequestStatus status, {
    String? response,
    String? processedBy,
  }) async {
    await _callCallableWithFallback(
      name: 'processDataRequest',
      payload: {
        'requestId': requestId,
        'status': status.name,
        if (response != null && response.trim().isNotEmpty)
          'response': response,
        if (processedBy != null && processedBy.trim().isNotEmpty)
          'processedBy': processedBy,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> exportCandidateData() {
    return _callCallableWithFallback(
      name: 'exportCandidateData',
      payload: const <String, dynamic>{},
    );
  }

  // --- Consents ---
  @override
  Future<ConsentRecord> saveConsent(ConsentRecord record) async {
    const defaultVersion = '2026.04';
    const defaultText =
        'Acepto el uso de IA en procesos de evaluación de candidatura.';

    final scopes = record.scope.isEmpty
        ? const <String>['ai_interview']
        : record.scope;
    final payload = <String, dynamic>{
      'companyId': record.companyId,
      'type': record.type.isEmpty ? 'ai_granular' : record.type,
      'scope': scopes,
      'consentTextVersion': record.consentTextVersion.isEmpty
          ? (record.informationNoticeVersion.isEmpty
                ? defaultVersion
                : record.informationNoticeVersion)
          : record.consentTextVersion,
      'consentText': record.consentTextSnapshot?.trim().isNotEmpty == true
          ? record.consentTextSnapshot!.trim()
          : defaultText,
    };

    final response = await _callCallableWithFallback(
      name: 'grantAiConsent',
      payload: payload,
    );
    final id = response['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      throw StateError('grantAiConsent did not return a valid id.');
    }

    final snapshot = await _firestore
        .collection('consentRecords')
        .doc(id)
        .get();
    final data =
        snapshot.data() ?? <String, dynamic>{...record.toJson(), ...response};
    return ConsentRecord.fromJson(data, id: id);
  }

  @override
  Future<ConsentRecord?> getConsent(
    String candidateUid,
    String companyId,
    String type,
  ) async {
    final snapshot = await _firestore
        .collection('consentRecords')
        .where('candidateUid', isEqualTo: candidateUid)
        .where('companyId', isEqualTo: companyId)
        .where('type', isEqualTo: type)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ConsentRecord.fromJson(
      snapshot.docs.first.data(),
      id: snapshot.docs.first.id,
    );
  }

  @override
  Stream<List<ConsentRecord>> getConsents(String candidateUid) {
    return _firestore
        .collection('consentRecords')
        .where('candidateUid', isEqualTo: candidateUid)
        .orderBy('grantedAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => ConsentRecord.fromJson(d.data(), id: d.id))
              .toList(),
        );
  }

  @override
  Future<void> upsertSalaryBenchmark({
    required String companyId,
    required String roleKeyOrTitle,
    double? maleAverageSalary,
    double? femaleAverageSalary,
    double? nonBinaryAverageSalary,
    int sampleSize = 0,
  }) async {
    await _callCallableWithFallback(
      name: 'upsertSalaryBenchmark',
      payload: {
        'companyId': companyId,
        'roleKey': roleKeyOrTitle,
        'maleAverageSalary': ?maleAverageSalary,
        'femaleAverageSalary': ?femaleAverageSalary,
        'nonBinaryAverageSalary': ?nonBinaryAverageSalary,
        'sampleSize': sampleSize < 0 ? 0 : sampleSize,
      },
    );
  }

  Future<Map<String, dynamic>> _callCallableWithFallback({
    required String name,
    required Map<String, dynamic> payload,
  }) async {
    return _callables.callMap(name: name, payload: payload);
  }
}
