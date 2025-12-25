import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumService {
  CurriculumService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _docRef(String candidateUid) {
    return _firestore
        .collection('candidates')
        .doc(candidateUid)
        .collection('curriculum')
        .doc('main');
  }

  Future<Curriculum> fetchCurriculum(String candidateUid) async {
    final snapshot = await _docRef(candidateUid).get();
    if (!snapshot.exists) {
      return Curriculum.empty();
    }
    final data = snapshot.data();
    if (data == null) return Curriculum.empty();
    return Curriculum.fromJson(data);
  }

  Future<Curriculum> saveCurriculum({
    required String candidateUid,
    required Curriculum curriculum,
  }) async {
    final data = curriculum.toJson()
      ..['updated_at'] = FieldValue.serverTimestamp();
    await _docRef(candidateUid).set(data, SetOptions(merge: true));
    final snapshot = await _docRef(candidateUid).get();
    final refreshed = snapshot.data();
    if (refreshed == null) return curriculum;
    return Curriculum.fromJson(refreshed);
  }
}

