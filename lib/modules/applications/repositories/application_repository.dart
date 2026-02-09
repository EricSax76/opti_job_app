import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/data/mappers/application_mapper.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
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
    required String jobOfferId,
    required String candidateUid,
  }) async {
    final query = await _firestore
        .collection('applications')
        .where('jobOfferId', isEqualTo: jobOfferId)
        .where('candidateId', isEqualTo: candidateUid)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<List<Application>> getApplicationsForOffer({
    required String jobOfferId,
    required String companyUid,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('applications')
        .where('jobOfferId', isEqualTo: jobOfferId);
    if (companyUid.isNotEmpty) {
      query = query.where('companyUid', isEqualTo: companyUid);
    }

    final snapshot = await query.get();
    final applications = snapshot.docs
        .map((doc) => ApplicationMapper.fromFirestore(doc.data(), id: doc.id))
        .toList(growable: false);
    applications.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return applications;
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
        .map((doc) => ApplicationMapper.fromFirestore(doc.data(), id: doc.id))
        .toList();

    final jobOfferIds = applications
        .map((application) => application.jobOfferId)
        .toSet()
        .toList();

    // But wait, candidateApplicationEntry likely maps applications to Offers.
    // Application has jobOfferId (String). CandidateApplicationEntry links them.

    // We need to fetch offers.
    final Map<String, JobOffer> offersMap = {};

    // Chunk size 5 because we might expand IDs x2 (String + Int) and limit is 10
    for (final chunk in _chunk(jobOfferIds, 5)) {
      final idsToQuery = <dynamic>[];
      for (final id in chunk) {
        idsToQuery.add(id);
        final intId = int.tryParse(id);
        if (intId != null) idsToQuery.add(intId);
      }

      final jobOffersQuery = await _firestore
          .collection('jobOffers')
          .where('id', whereIn: idsToQuery)
          .get();

      for (final doc in jobOffersQuery.docs) {
        final offer = JobOffer.fromJson(doc.data());
        // Map both String ID and original legacy Int ID (as string) to this offer
        offersMap[offer.id] = offer;
        // Note: JobOffer.id is always normalized to String by fromJson.
        // So relying on offer.id is correct.
      }
    }

    return applications
        .map(
          (application) => CandidateApplicationEntry(
            application: application,
            offer: offersMap[application.jobOfferId],
          ),
        )
        .toList();
  }

  Future<Application?> getApplicationForCandidateOffer({
    required String jobOfferId,
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
    return ApplicationMapper.fromFirestore(doc.data(), id: doc.id);
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
