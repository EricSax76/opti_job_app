import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:infojobs_flutter_app/data/models/candidate.dart';
import 'package:infojobs_flutter_app/data/models/company.dart';

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
}
