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
    // Check for String ID
    var query = await _firestore
        .collection('applications')
        .where('jobOfferId', isEqualTo: jobOfferId)
        .where('candidateId', isEqualTo: candidateUid)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) return true;

    // Check for Int ID if applicable
    final intId = int.tryParse(jobOfferId);
    if (intId != null) {
       final legacyQuery = await _firestore
        .collection('applications')
        .where('jobOfferId', isEqualTo: intId)
        .where('candidateId', isEqualTo: candidateUid)
        .limit(1)
        .get();
       if (legacyQuery.docs.isNotEmpty) return true;
    }

    return false;
  }

  Future<List<Application>> getApplicationsForOffer({
    required String jobOfferId,
    required String companyUid,
  }) async {
    final collection = _firestore.collection('applications');

    Future<List<Application>> runQuery({
      required String offerField,
      required dynamic offerIdValue, // Dynamic to support verifying int vs string
      required String companyField,
      bool includeCompany = true,
    }) async {
      var query = collection.where(offerField, isEqualTo: offerIdValue);
      if (includeCompany && companyUid.isNotEmpty) {
        query = query.where(companyField, isEqualTo: companyUid);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ApplicationMapper.fromFirestore(doc.data(), id: doc.id))
          .toList();
    }

    // Identify IDs to query (String and optionally Int)
    final idsToQuery = <dynamic>[jobOfferId];
    final intId = int.tryParse(jobOfferId);
    if (intId != null) idsToQuery.add(intId);

    final fallbackResults = <String, Application>{};
    
    Future<void> merge(List<Application> apps) async {
       for (final app in apps) {
        if (app.id == null) continue;
        fallbackResults[app.id!] = app;
      }
    }

    // Run queries for all ID variants and field variants
    for (final idValue in idsToQuery) {
       await merge(await runQuery(
         offerField: 'jobOfferId', 
         offerIdValue: idValue, 
         companyField: 'companyUid'
       ));
       
       // Also check snake_case fields
       await merge(await runQuery(
         offerField: 'job_offer_id', 
         offerIdValue: idValue, 
         companyField: 'companyUid'
       ));
       await merge(await runQuery(
         offerField: 'jobOfferId', 
         offerIdValue: idValue, 
         companyField: 'company_uid'
       ));
       await merge(await runQuery(
         offerField: 'job_offer_id', 
         offerIdValue: idValue, 
         companyField: 'company_uid'
       ));
    }

    // If still empty, try without company filter (as per original logic fallback)
    if (fallbackResults.isEmpty) {
       for (final idValue in idsToQuery) {
          await merge(await runQuery(
            offerField: 'jobOfferId',
            offerIdValue: idValue,
            companyField: 'companyUid',
            includeCompany: false,
          ));
          await merge(await runQuery(
            offerField: 'job_offer_id',
            offerIdValue: idValue,
            companyField: 'companyUid',
            includeCompany: false,
          ));
       }
    }

    return fallbackResults.values.toList();
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
    var query = await _firestore
        .collection('applications')
        .where('jobOfferId', isEqualTo: jobOfferId)
        .where('candidateId', isEqualTo: candidateUid)
        .limit(1)
        .get();
        
    if (query.docs.isEmpty) {
        final intId = int.tryParse(jobOfferId);
        if (intId != null) {
           query = await _firestore
            .collection('applications')
            .where('jobOfferId', isEqualTo: intId)
            .where('candidateId', isEqualTo: candidateUid)
            .limit(1)
            .get();
        }
    }
    
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
