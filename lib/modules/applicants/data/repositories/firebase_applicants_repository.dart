import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/data/mappers/application_mapper.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';

class FirebaseApplicantsRepository implements ApplicantsRepository {
  FirebaseApplicantsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Application>> getApplicationsForOffer({
    required String jobOfferId,
    required String companyUid,
  }) async {
    final normalizedOfferId = jobOfferId.trim();
    if (normalizedOfferId.isEmpty) return const [];

    final byOffer = await getApplicationsForOffers(
      jobOfferIds: [normalizedOfferId],
      companyUid: companyUid,
    );
    return byOffer[normalizedOfferId] ?? const <Application>[];
  }

  @override
  Future<Map<String, List<Application>>> getApplicationsForOffers({
    required Iterable<String> jobOfferIds,
    required String companyUid,
  }) async {
    final normalizedOfferIds = jobOfferIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedOfferIds.isEmpty) return const {};

    final applicationsByOffer = <String, List<Application>>{
      for (final offerId in normalizedOfferIds) offerId: <Application>[],
    };
    for (final chunk in _chunk(normalizedOfferIds, 10)) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('applications')
          .where('jobOfferId', whereIn: chunk);
      if (companyUid.isNotEmpty) {
        query = query.where('companyUid', isEqualTo: companyUid);
      }

      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        final app = ApplicationMapper.fromFirestore(doc.data(), id: doc.id);
        final normalizedOfferId = app.jobOfferId.trim();
        if (normalizedOfferId.isEmpty) continue;
        final bucket = applicationsByOffer[normalizedOfferId];
        if (bucket == null) continue;
        bucket.add(app);
      }
    }

    for (final applications in applicationsByOffer.values) {
      applications.sort(_sortByMostRecent);
    }
    return applicationsByOffer;
  }

  @override
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await _firestore.collection('applications').doc(applicationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  static int _sortByMostRecent(Application a, Application b) {
    final aDate = a.updatedAt ?? a.createdAt;
    final bDate = b.updatedAt ?? b.createdAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }
}
