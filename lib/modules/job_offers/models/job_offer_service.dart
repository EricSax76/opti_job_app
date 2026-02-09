import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/data/mappers/job_offer_mapper.dart';

class JobOffersPageCursor {
  const JobOffersPageCursor._(this._snapshot);

  final QueryDocumentSnapshot<Map<String, dynamic>> _snapshot;
}

class JobOffersPage {
  const JobOffersPage({
    required this.offers,
    required this.hasMore,
    required this.nextPageCursor,
  });

  final List<JobOffer> offers;
  final bool hasMore;
  final JobOffersPageCursor? nextPageCursor;
}

class JobOfferService {
  static const int _defaultPageSize = 20;

  JobOfferService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobOffers');

  Future<JobOffersPage> fetchJobOffersPage({
    String? jobType,
    int limit = _defaultPageSize,
    JobOffersPageCursor? startAfter,
  }) async {
    final normalizedJobType = jobType?.trim();
    Query<Map<String, dynamic>> query = _collection.orderBy(
      'created_at',
      descending: true,
    );
    if (normalizedJobType != null && normalizedJobType.isNotEmpty) {
      query = query.where('job_type', isEqualTo: normalizedJobType);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter._snapshot);
    }
    final safeLimit = limit > 0 ? limit : _defaultPageSize;
    final snapshot = await query.limit(safeLimit).get();
    return _toPage(snapshot.docs, safeLimit);
  }

  Future<List<JobOffer>> fetchJobOffers({
    String? jobType,
    int limit = _defaultPageSize,
    JobOffersPageCursor? startAfter,
  }) async {
    final firstPage = await fetchJobOffersPage(
      jobType: jobType,
      limit: limit,
      startAfter: startAfter,
    );
    if (startAfter != null || !firstPage.hasMore) {
      return firstPage.offers;
    }

    final offers = <JobOffer>[...firstPage.offers];
    var cursor = firstPage.nextPageCursor;
    while (cursor != null) {
      final page = await fetchJobOffersPage(
        jobType: jobType,
        limit: limit,
        startAfter: cursor,
      );
      offers.addAll(page.offers);
      if (!page.hasMore) break;
      cursor = page.nextPageCursor;
    }
    return offers;
  }

  Future<JobOffersPage> fetchJobOffersByCompanyUidPage(
    String companyUid, {
    int limit = _defaultPageSize,
    JobOffersPageCursor? startAfter,
  }) async {
    final normalizedCompanyUid = companyUid.trim();
    if (normalizedCompanyUid.isEmpty) {
      throw ArgumentError.value(companyUid, 'companyUid', 'must not be empty');
    }

    try {
      Query<Map<String, dynamic>> query = _collection
          .where('company_uid', isEqualTo: normalizedCompanyUid)
          .orderBy('created_at', descending: true);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter._snapshot);
      }
      final safeLimit = limit > 0 ? limit : _defaultPageSize;
      final snapshot = await query.limit(safeLimit).get();
      return _toPage(snapshot.docs, safeLimit);
    } on FirebaseException catch (error) {
      if (_isMissingIndexError(error)) {
        throw StateError(
          'Falta un indice de Firestore para consultar ofertas por empresa '
          'ordenadas por fecha.',
        );
      }
      rethrow;
    }
  }

  Future<List<JobOffer>> fetchJobOffersByCompanyUid(
    String companyUid, {
    int limit = _defaultPageSize,
    JobOffersPageCursor? startAfter,
  }) async {
    final firstPage = await fetchJobOffersByCompanyUidPage(
      companyUid,
      limit: limit,
      startAfter: startAfter,
    );
    if (startAfter != null || !firstPage.hasMore) {
      return firstPage.offers;
    }

    final offers = <JobOffer>[...firstPage.offers];
    var cursor = firstPage.nextPageCursor;
    while (cursor != null) {
      final page = await fetchJobOffersByCompanyUidPage(
        companyUid,
        limit: limit,
        startAfter: cursor,
      );
      offers.addAll(page.offers);
      if (!page.hasMore) break;
      cursor = page.nextPageCursor;
    }
    return offers;
  }

  JobOffersPage _toPage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int limit,
  ) {
    final offers = docs.map(_mapOfferDoc).toList(growable: false);
    final hasMore = docs.length == limit;
    return JobOffersPage(
      offers: offers,
      hasMore: hasMore,
      nextPageCursor: hasMore && docs.isNotEmpty
          ? JobOffersPageCursor._(docs.last)
          : null,
    );
  }

  JobOffer _mapOfferDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final rawId = data['id']?.toString().trim();
    if (rawId == null || rawId.isEmpty) {
      return JobOfferMapper.fromFirestore({...data, 'id': doc.id});
    }
    return JobOfferMapper.fromFirestore(data);
  }

  bool _isMissingIndexError(FirebaseException error) {
    return error.code == 'failed-precondition' &&
        (error.message?.toLowerCase().contains('index') ?? false);
  }

  Future<JobOffer> fetchJobOffer(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }

    final docSnapshot = await _collection.doc(normalizedId).get();
    final docData = docSnapshot.data();
    if (docSnapshot.exists && docData != null) {
      final withId = <String, dynamic>{...docData};
      final rawId = withId['id']?.toString().trim();
      if (rawId == null || rawId.isEmpty) {
        withId['id'] = docSnapshot.id;
      }
      return JobOfferMapper.fromFirestore(withId);
    }

    var snapshot = await _collection
        .where('id', isEqualTo: normalizedId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      final intId = int.tryParse(normalizedId);
      if (intId != null) {
        snapshot = await _collection
            .where('id', isEqualTo: intId)
            .limit(1)
            .get();
      }
    }

    if (snapshot.docs.isEmpty) {
      throw StateError('Oferta no encontrada (ID: $normalizedId).');
    }
    return _mapOfferDoc(snapshot.docs.first);
  }

  Future<JobOffer> createJobOffer(JobOfferPayload payload) async {
    final docRef = _collection.doc();
    final offerId = docRef.id;
    final payloadData = payload.toJson();
    final offerData = <String, dynamic>{
      ...payloadData,
      'id': offerId,
      'created_at': FieldValue.serverTimestamp(),
    };

    await docRef.set(offerData);

    // Look up what we just wrote to return complete object including server timestamp
    final storedDoc = await docRef.get();
    final storedData =
        storedDoc.data() ??
        {
          ...payloadData,
          'id': offerId,
          'created_at': DateTime.now().toIso8601String(),
        };
    return JobOfferMapper.fromFirestore(storedData);
  }
}

class JobOfferPayload {
  const JobOfferPayload({
    required this.title,
    required this.description,
    required this.location,
    required this.companyId,
    required this.companyUid,
    required this.companyName,
    this.companyAvatarUrl,
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.jobType,
    this.keyIndicators,
  });

  final String title;
  final String description;
  final String location;
  final int companyId;
  final String companyUid;
  final String companyName;
  final String? companyAvatarUrl;
  final String? salaryMin;
  final String? salaryMax;
  final String? education;
  final String? jobType;
  final String? keyIndicators;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'company_id': companyId,
      'company_uid': companyUid,
      'company_name': companyName,
      'company_avatar_url': companyAvatarUrl,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'education': education,
      'job_type': jobType,
      'key_indicators': keyIndicators,
    };
  }
}
