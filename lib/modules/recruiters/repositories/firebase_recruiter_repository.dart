import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:opti_job_app/core/utils/callable_with_fallback.dart';

import 'package:opti_job_app/modules/recruiters/models/invitation.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';
import 'package:opti_job_app/modules/recruiters/repositories/recruiter_repository.dart';

/// Implementación de [RecruiterRepository] sobre Firebase Firestore.
class FirebaseRecruiterRepository implements RecruiterRepository {
  FirebaseRecruiterRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required FirebaseFunctions fallbackFunctions,
  }) : _db = firestore,
       _callables = CallableWithFallback(
         functions: functions,
         fallbackFunctions: fallbackFunctions,
       );

  final FirebaseFirestore _db;
  final CallableWithFallback _callables;

  CollectionReference<Map<String, dynamic>> get _recruiters =>
      _db.collection('recruiters');

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('invitations');

  @override
  Future<Recruiter?> getRecruiter(String uid) async {
    final doc = await _recruiters.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return Recruiter.fromFirestore({...doc.data()!, 'uid': doc.id});
  }

  @override
  Future<String> createInvitation({
    required RecruiterRole role,
    String? email,
  }) async {
    final payload = <String, dynamic>{
      'role': role.toFirestoreString(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };
    final data = await _callCallableWithFallback(
      functionName: 'createInvitation',
      payload: payload,
    );
    final code = data['code']?.toString().trim() ?? '';
    if (code.isEmpty) {
      throw StateError('createInvitation no devolvió un código válido.');
    }
    return code;
  }

  @override
  Future<void> acceptInvitation({
    required String code,
    required String name,
  }) async {
    await _callCallableWithFallback(
      functionName: 'acceptInvitation',
      payload: <String, dynamic>{
        'code': code.trim().toUpperCase(),
        'name': name.trim(),
      },
    );
  }

  @override
  Future<void> updateRecruiterRole(String uid, RecruiterRole role) async {
    await _callCallableWithFallback(
      functionName: 'updateRecruiterRole',
      payload: <String, dynamic>{
        'targetUid': uid.trim(),
        'newRole': role.toFirestoreString(),
      },
    );
  }

  @override
  Future<void> removeRecruiter(String uid) async {
    await _callCallableWithFallback(
      functionName: 'removeRecruiter',
      payload: <String, dynamic>{'targetUid': uid.trim()},
    );
  }

  @override
  Stream<List<Recruiter>> watchCompanyRecruiters(String companyId) {
    return _recruiters
        .where('companyId', isEqualTo: companyId)
        .where('status', whereIn: ['active', 'invited'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Recruiter.fromFirestore({...doc.data(), 'uid': doc.id}),
              )
              .toList(),
        );
  }

  @override
  Future<Invitation?> getInvitation(String code) async {
    final doc = await _invitations.doc(code.toUpperCase()).get();
    if (!doc.exists || doc.data() == null) return null;
    return Invitation.fromFirestore({...doc.data()!, 'code': doc.id});
  }

  Future<Map<String, dynamic>> _callCallableWithFallback({
    required String functionName,
    required Map<String, dynamic> payload,
  }) async {
    return _callables.callMap(name: functionName, payload: payload);
  }
}
