import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

class ApplicationRepository {
  ApplicationRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<void> createApplication({
    required JobOffer jobOffer,
    required Candidate candidate,
    int? candidateProfileId,
  }) async {
    final application = Application(
      jobOfferId: jobOffer.id,
      jobOfferTitle: jobOffer.title,
      companyUid: jobOffer.companyUid,
      candidateUid: candidate.uid,
      candidateName: candidate.name,
      candidateEmail: candidate.email,
      candidateProfileId: candidateProfileId ?? candidate.id,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final data = application.toJson()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('applications').add(data);
  }

  Future<bool> applicationExists({
    required int jobOfferId,
    required String candidateUid,
  }) async {
    final query = await _firestore
        .collection('applications')
        .where('jobOfferId', isEqualTo: jobOfferId)
        .where('candidateId', isEqualTo: candidateUid)
        .get();

    return query.docs.isNotEmpty;
  }

  Future<List<Application>> getApplicationsForOffer({
    required int jobOfferId,
    required String companyUid,
  }) async {
    final query = await _firestore
        .collection('applications')
        .where('companyUid', isEqualTo: companyUid)
        .where('jobOfferId', isEqualTo: jobOfferId)
        .get();

    return query.docs
        .map((doc) => Application.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await _firestore.collection('applications').doc(applicationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<JobOffer>> getApplicationsForCandidate({
    required String candidateUid,
  }) async {
    // 1. Find all applications for the given candidate.
    final applicationQuery = await _firestore
        .collection('applications')
        .where('candidateId', isEqualTo: candidateUid)
        .get();

    if (applicationQuery.docs.isEmpty) {
      return [];
    }

    // 2. Extract the job offer IDs from the applications.
    final jobOfferIds = applicationQuery.docs
        .map((doc) => doc.data()['jobOfferId'] as int)
        .toList();

    // 3. Fetch the corresponding job offers using the IDs.
    final jobOffersQuery = await _firestore
        .collection('jobOffers')
        .where('id', whereIn: jobOfferIds)
        .get();

    // 4. Convert the documents to JobOffer objects and return them.
    return jobOffersQuery.docs
        .map((doc) => JobOffer.fromJson(doc.data()))
        .toList();
  }
}
