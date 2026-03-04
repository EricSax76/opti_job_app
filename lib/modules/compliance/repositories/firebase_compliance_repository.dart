import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/compliance/models/audit_log.dart';
import 'package:opti_job_app/modules/compliance/models/consent_record.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';

class FirebaseComplianceRepository implements AuditRepository, DataRequestRepository, ConsentRepository {
  FirebaseComplianceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // --- Audit ---
  @override
  Future<void> logAction(AuditLog log) async {
    await _firestore.collection('auditLogs').add({
      ...log.toJson(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AuditLog>> getLogs({String? actorUid, String? targetId, String? companyId}) {
    Query query = _firestore.collection('auditLogs');
    if (actorUid != null) query = query.where('actorUid', isEqualTo: actorUid);
    if (targetId != null) query = query.where('targetId', isEqualTo: targetId);
    if (companyId != null) query = query.where('companyId', isEqualTo: companyId);
    
    return query.orderBy('timestamp', descending: true).snapshots().map(
      (s) => s.docs.map((d) => AuditLog.fromJson(d.data() as Map<String, dynamic>, id: d.id)).toList()
    );
  }

  // --- Data Requests ---
  @override
  Future<DataRequest> submitRequest(DataRequest request) async {
    final docRef = await _firestore.collection('dataRequests').add({
      ...request.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'dueAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
    return DataRequest.fromJson(request.toJson(), id: docRef.id);
  }

  @override
  Stream<List<DataRequest>> getRequests(String candidateUid) {
    return _firestore.collection('dataRequests')
      .where('candidateUid', isEqualTo: candidateUid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DataRequest.fromJson(d.data(), id: d.id)).toList());
  }

  @override
  Stream<List<DataRequest>> getAllRequests() {
    return _firestore.collection('dataRequests')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => DataRequest.fromJson(d.data(), id: d.id)).toList());
  }

  @override
  Future<void> updateRequestStatus(String requestId, DataRequestStatus status, {String? response, String? processedBy}) async {
    await _firestore.collection('dataRequests').doc(requestId).update({
      'status': status.name,
      ...?response != null ? {'response': response} : null,
      ...?processedBy != null ? {'processedBy': processedBy} : null,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Consents ---
  @override
  Future<ConsentRecord> saveConsent(ConsentRecord record) async {
    final docRef = _firestore.collection('consentRecords').doc();
    final data = {
      ...record.toJson(),
      'grantedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365 * 3))),
    };
    await docRef.set(data);
    return ConsentRecord.fromJson(record.toJson(), id: docRef.id);
  }

  @override
  Future<ConsentRecord?> getConsent(String candidateUid, String companyId, String type) async {
    final snapshot = await _firestore.collection('consentRecords')
      .where('candidateUid', isEqualTo: candidateUid)
      .where('companyId', isEqualTo: companyId)
      .where('type', isEqualTo: type)
      .limit(1)
      .get();
    
    if (snapshot.docs.isEmpty) return null;
    return ConsentRecord.fromJson(snapshot.docs.first.data(), id: snapshot.docs.first.id);
  }

  @override
  Stream<List<ConsentRecord>> getConsents(String candidateUid) {
    return _firestore.collection('consentRecords')
      .where('candidateUid', isEqualTo: candidateUid)
      .orderBy('grantedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ConsentRecord.fromJson(d.data(), id: d.id)).toList());
  }
}
