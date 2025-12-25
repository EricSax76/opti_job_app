import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/aplications/models/candidate_application_entry.dart';
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

  Future<List<CandidateApplicationEntry>> getApplicationsForCandidate({
    required String candidateUid,
  }) async {
    final applicationQuery = await _firestore
        .collection('applications')
        .where('candidateId', isEqualTo: candidateUid)
        .get();

    if (applicationQuery.docs.isEmpty) {
      return [];
    }

    final applications = applicationQuery.docs
        .map((doc) => Application.fromJson(doc.data(), id: doc.id))
        .toList();

    final jobOfferIds = applications
        .map((application) => application.jobOfferId)
        .toSet()
        .toList();

    final offersById = <int, JobOffer>{};
    for (final chunk in _chunk(jobOfferIds, 10)) {
      final jobOffersQuery = await _firestore
          .collection('jobOffers')
          .where('id', whereIn: chunk)
          .get();
      for (final doc in jobOffersQuery.docs) {
        final offer = JobOffer.fromJson(doc.data());
        offersById[offer.id] = offer;
      }
    }

    return applications
        .map(
          (application) => CandidateApplicationEntry(
            application: application,
            offer: offersById[application.jobOfferId],
          ),
        )
        .toList();
  }

  Future<Application?> getApplicationForCandidateOffer({
    required int jobOfferId,
    required String candidateUid,
  }) async {
    final query = await _firestore
        .collection('applications')
        .where('jobOfferId', isEqualTo: jobOfferId)
        .where('candidateId', isEqualTo: candidateUid)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return Application.fromJson(doc.data(), id: doc.id);
  }
}

List<List<T>> _chunk<T>(List<T> items, int size) {
  if (items.isEmpty) return const [];
  final chunks = <List<T>>[];
  for (var i = 0; i < items.length; i += size) {
    final end = i + size > items.length ? items.length : i + size;
    chunks.add(items.sublist(i, end));
  }
  return chunks;
}
