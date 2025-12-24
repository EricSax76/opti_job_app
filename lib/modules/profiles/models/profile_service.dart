import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

class ProfileService {
  ProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Candidate> fetchCandidateProfile(int id) async {
    final query = await _firestore
        .collection('candidates')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('Perfil de candidato no encontrado.');
    }
    final data = query.docs.first.data();
    return Candidate.fromJson(data);
  }

  Future<Company> fetchCompanyProfile(int id) async {
    final query = await _firestore
        .collection('companies')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('Perfil de empresa no encontrado.');
    }
    final data = query.docs.first.data();
    return Company.fromJson(data);
  }

  Future<Candidate> updateCandidateProfile({
    required String uid,
    required String name,
  }) async {
    final docRef = _firestore.collection('candidates').doc(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Perfil de candidato no encontrado.');
    }
    await docRef.update({
      'name': name,
      'updated_at': FieldValue.serverTimestamp(),
    });
    final updatedSnapshot = await docRef.get();
    final data = updatedSnapshot.data();
    if (data == null) {
      throw StateError('No se pudo actualizar el perfil.');
    }
    return Candidate.fromJson(data);
  }
}
