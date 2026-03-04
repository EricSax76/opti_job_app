import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/recruiters/models/invitation.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';
import 'package:opti_job_app/modules/recruiters/repositories/recruiter_repository.dart';

/// Implementación de [RecruiterRepository] sobre Firebase Firestore.
class FirebaseRecruiterRepository implements RecruiterRepository {
  FirebaseRecruiterRepository({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

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
  Future<void> createRecruiter(Recruiter recruiter) async {
    await _recruiters.doc(recruiter.uid).set(
      recruiter.toFirestore(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateRecruiterRole(String uid, RecruiterRole role) async {
    await _recruiters.doc(uid).update({
      'role': role.toFirestoreString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> disableRecruiter(String uid) async {
    await _recruiters.doc(uid).update({
      'status': 'disabled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
                (doc) => Recruiter.fromFirestore({
                  ...doc.data(),
                  'uid': doc.id,
                }),
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
}
