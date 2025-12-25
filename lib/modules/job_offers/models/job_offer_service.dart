import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class JobOfferService {
  JobOfferService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobOffers');

  Future<List<JobOffer>> fetchJobOffers({String? jobType}) async {
    Query<Map<String, dynamic>> query = _collection.orderBy(
      'created_at',
      descending: true,
    );
    if (jobType != null && jobType.isNotEmpty) {
      query = query.where('job_type', isEqualTo: jobType);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => JobOffer.fromJson(doc.data())).toList();
  }

  Future<List<JobOffer>> fetchJobOffersByCompanyUid(String companyUid) async {
    try {
      final snapshot = await _collection
          .where('company_uid', isEqualTo: companyUid)
          .orderBy('created_at', descending: true)
          .get();
      return _mapOffers(snapshot.docs);
    } on FirebaseException catch (error) {
      final needsFallback =
          error.code == 'failed-precondition' &&
          (error.message?.toLowerCase().contains('index') ?? false);
      if (!needsFallback) rethrow;

      final snapshot = await _collection
          .where('company_uid', isEqualTo: companyUid)
          .get();
      final offers = _mapOffers(snapshot.docs);
      offers.sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return offers;
    }
  }

  List<JobOffer> _mapOffers(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) => JobOffer.fromJson(doc.data())).toList();
  }

  Future<JobOffer> fetchJobOffer(int id) async {
    final snapshot = await _collection
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      throw StateError('Oferta no encontrada.');
    }
    final data = snapshot.docs.first.data();
    return JobOffer.fromJson(data);
  }

  Future<JobOffer> createJobOffer(JobOfferPayload payload) async {
    final offerId = DateTime.now().millisecondsSinceEpoch;
    final payloadData = payload.toJson();
    final offerData = <String, dynamic>{
      ...payloadData,
      'id': offerId,
      'created_at': FieldValue.serverTimestamp(),
    };

    final docRef = await _collection.add(offerData);
    final storedDoc = await docRef.get();
    final storedData =
        storedDoc.data() ??
        {
          ...payloadData,
          'id': offerId,
          'created_at': DateTime.now().toIso8601String(),
        };
    return JobOffer.fromJson(storedData);
  }
}

class JobOfferPayload {
  const JobOfferPayload({
    required this.title,
    required this.description,
    required this.location,
    required this.companyId,
    required this.companyUid,
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
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'education': education,
      'job_type': jobType,
      'key_indicators': keyIndicators,
    };
  }
}
