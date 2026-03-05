import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  JobOfferService({
    required FirebaseFirestore firestore,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _firestore = firestore,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _fallbackFunctions = fallbackFunctions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseFunctions _fallbackFunctions;

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
      query = query.startAfterDocument(startAfter._snapshot);
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
    final firstPage = await fetchJobOffersPage(
      jobType: jobType,
      provinceId: provinceId,
      municipalityId: municipalityId,
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
        provinceId: provinceId,
        municipalityId: municipalityId,
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
    final payloadData = payload.toJson();
    final offerId = await _createOfferSecure(payloadData);
    return fetchJobOffer(offerId);
  }

  Future<String> _createOfferSecure(Map<String, dynamic> payload) async {
    try {
      final result = await _functions
          .httpsCallable('createJobOfferSecure')
          .call(payload);
      return _extractOfferIdFromResult(result);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'not-found' && error.code != 'unimplemented') {
        rethrow;
      }
      final fallbackResult = await _fallbackFunctions
          .httpsCallable('createJobOfferSecure')
          .call(payload);
      return _extractOfferIdFromResult(fallbackResult);
    }
  }

  String _extractOfferIdFromResult(HttpsCallableResult<dynamic> result) {
    final data = result.data;
    if (data is Map) {
      final id = data['offerId']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
    }
    throw StateError('createJobOfferSecure did not return a valid offerId.');
  }
}

class JobOfferPayload {
  const JobOfferPayload({
    required this.title,
    required this.description,
    required this.location,
    this.provinceId,
    this.provinceName,
    this.municipalityId,
    this.municipalityName,
    required this.companyId,
    required this.companyUid,
    required this.companyName,
    this.companyAvatarUrl,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.salaryPeriod,
    this.education,
    this.jobCategory,
    this.workSchedule,
    this.contractType,
    this.jobType,
    this.keyIndicators,
    this.pipelineId,
    this.pipelineStages,
    this.knockoutQuestions,
    this.languageCheckResult,
  });

  final String title;
  final String description;
  final String location;
  final String? provinceId;
  final String? provinceName;
  final String? municipalityId;
  final String? municipalityName;
  final int companyId;
  final String companyUid;
  final String companyName;
  final String? companyAvatarUrl;
  final String salaryMin;
  final String salaryMax;
  final String salaryCurrency;
  final String salaryPeriod;
  final String? education;
  final String? jobCategory;
  final String? workSchedule;
  final String? contractType;
  final String? jobType;
  final String? keyIndicators;
  final String? pipelineId;
  final List<dynamic>? pipelineStages;
  final List<dynamic>? knockoutQuestions;
  final Map<String, dynamic>? languageCheckResult;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'province_id': _normalizeNullableString(provinceId),
      'province_name': _normalizeNullableString(provinceName),
      'municipality_id': _normalizeNullableString(municipalityId),
      'municipality_name': _normalizeNullableString(municipalityName),
      'company_id': companyId,
      'company_uid': companyUid,
      'company_name': companyName,
      'company_avatar_url': companyAvatarUrl,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'salary_currency': salaryCurrency,
      'salary_period': salaryPeriod,
      'education': education,
      'job_category': jobCategory,
      'work_schedule': workSchedule,
      'contract_type': contractType,
      'job_type': jobType,
      'key_indicators': keyIndicators,
      if (pipelineId != null) 'pipelineId': pipelineId,
      if (pipelineStages != null) 'pipelineStages': pipelineStages,
      if (knockoutQuestions != null) 'knockoutQuestions': knockoutQuestions,
      'language_check_result': languageCheckResult,
    };
  }
}

String? _normalizeNullableString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
