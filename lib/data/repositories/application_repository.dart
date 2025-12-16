import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/data/models/application.dart';
import 'package:opti_job_app/data/models/job_offer.dart';

class ApplicationRepository {
  ApplicationRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

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

  Future<List<JobOffer>> getApplicationsForCandidate({
    required int candidateId,
  }) async {
    // 1. Find all applications for the given candidate.
    final applicationQuery = await _firestore
        .collection('applications')
        .where('candidate_id', isEqualTo: candidateId)
        .get();

    if (applicationQuery.docs.isEmpty) {
      return [];
    }

    // 2. Extract the job offer IDs from the applications.
    final jobOfferIds = applicationQuery.docs
        .map((doc) => doc.data()['job_offer_id'] as int)
        .toList();

    // 3. Fetch the corresponding job offers using the IDs.
    final jobOffersQuery = await _firestore
        .collection('job_offers')
        .where('id', whereIn: jobOfferIds)
        .get();

    // 4. Convert the documents to JobOffer objects and return them.
    return jobOffersQuery.docs
        .map((doc) => JobOffer.fromJson(doc.data()))
        .toList();
  }
}
