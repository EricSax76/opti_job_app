import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/job_offers/data/mappers/job_offer_mapper.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offers_page.dart';

class JobOfferReadService {
  static const int _defaultPageSize = 20;

  JobOfferReadService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobOffers');

  Future<JobOffersPage> fetchJobOffersPage({
    String? jobType,
    String? provinceId,
    String? municipalityId,
    int limit = _defaultPageSize,
    JobOffersPageCursor? startAfter,
  }) async {
    final normalizedJobType = jobType?.trim();
    final normalizedProvinceId = _normalizeNullableString(provinceId);
    final normalizedMunicipalityId = _normalizeNullableString(municipalityId);
    Query<Map<String, dynamic>> query = _collection.orderBy(
      'created_at',
      descending: true,
    );
    if (normalizedJobType != null && normalizedJobType.isNotEmpty) {
      query = query.where('job_type', isEqualTo: normalizedJobType);
    }
    if (normalizedProvinceId != null) {
      query = query.where('province_id', isEqualTo: normalizedProvinceId);
    }
    if (normalizedMunicipalityId != null) {
      query = query.where(
        'municipality_id',
        isEqualTo: normalizedMunicipalityId,
      );
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter.snapshot);
    }
    final safeLimit = limit > 0 ? limit : _defaultPageSize;
    final snapshot = await query.limit(safeLimit).get();
    return _toPage(snapshot.docs, safeLimit);
  }

  Future<List<JobOffer>> fetchJobOffers({
    String? jobType,
    String? provinceId,
    String? municipalityId,
    int limit = _defaultPageSize,
    JobOffersPageCursor? startAfter,
  }) async {
    return _fetchAllPages(
      startAfter: startAfter,
      fetchPage: (cursor) {
        return fetchJobOffersPage(
          jobType: jobType,
          provinceId: provinceId,
          municipalityId: municipalityId,
          limit: limit,
          startAfter: cursor,
        );
      },
    );
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
        query = query.startAfterDocument(startAfter.snapshot);
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
    return _fetchAllPages(
      startAfter: startAfter,
      fetchPage: (cursor) {
        return fetchJobOffersByCompanyUidPage(
          companyUid,
          limit: limit,
          startAfter: cursor,
        );
      },
    );
  }

  Future<List<JobOffer>> _fetchAllPages({
    required JobOffersPageCursor? startAfter,
    required Future<JobOffersPage> Function(JobOffersPageCursor? startAfter)
    fetchPage,
  }) async {
    final firstPage = await fetchPage(startAfter);
    if (startAfter != null || !firstPage.hasMore) {
      return firstPage.offers;
    }

    final offers = <JobOffer>[...firstPage.offers];
    var cursor = firstPage.nextPageCursor;
    while (cursor != null) {
      final page = await fetchPage(cursor);
      offers.addAll(page.offers);
      if (!page.hasMore) break;
      cursor = page.nextPageCursor;
    }
    return offers;
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
          ? JobOffersPageCursor(docs.last)
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
}

String? _normalizeNullableString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
