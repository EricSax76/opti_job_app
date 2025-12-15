import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:opti_job_app/data/models/job_offer.dart';

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
    return snapshot.docs
        .map((doc) => JobOffer.fromJson(doc.data()))
        .toList();
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
    final storedData = storedDoc.data() ??
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
    this.salaryMin,
    this.salaryMax,
    this.education,
    this.jobType,
  });

  final String title;
  final String description;
  final String location;
  final String? salaryMin;
  final String? salaryMax;
  final String? education;
  final String? jobType;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'education': education,
      'job_type': jobType,
    };
  }
}
