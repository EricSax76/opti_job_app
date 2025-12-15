import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/data/models/application.dart';

class ApplicationRepository {
  ApplicationRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> createApplication({
    required int jobOfferId,
    required int candidateId,
  }) async {
    final application = Application(
      jobOfferId: jobOfferId,
      candidateId: candidateId,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('applications').add(application.toJson());
  }

  Future<bool> applicationExists({
    required int jobOfferId,
    required int candidateId,
  }) async {
    final query = await _firestore
        .collection('applications')
        .where('job_offer_id', isEqualTo: jobOfferId)
        .where('candidate_id', isEqualTo: candidateId)
        .get();

    return query.docs.isNotEmpty;
  }
}
