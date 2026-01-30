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
    final collection = _firestore.collection('applications');

    Future<List<Application>> runQuery({
      required String offerField,
      required dynamic offerIdValue,
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

    // Identify IDs to query
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
    
    for (final idValue in idsToQuery) {
        final primary = await runQuery(
          offerField: 'jobOfferId',
          offerIdValue: idValue,
          companyField: 'companyUid',
        );
        await merge(primary);
        
        await merge(
          await runQuery(offerField: 'job_offer_id', offerIdValue: idValue, companyField: 'companyUid'),
        );
        await merge(
          await runQuery(offerField: 'jobOfferId', offerIdValue: idValue, companyField: 'company_uid'),
        );
        await merge(
          await runQuery(offerField: 'job_offer_id', offerIdValue: idValue, companyField: 'company_uid'),
        );
    }

    if (fallbackResults.isEmpty) {
      for (final idValue in idsToQuery) {
        await merge(
          await runQuery(
            offerField: 'jobOfferId',
            offerIdValue: idValue,
            companyField: 'companyUid',
            includeCompany: false,
          ),
        );
        await merge(
          await runQuery(
            offerField: 'job_offer_id',
            offerIdValue: idValue,
            companyField: 'companyUid',
            includeCompany: false,
          ),
        );
      }
    }

    return fallbackResults.values.toList();
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
}
