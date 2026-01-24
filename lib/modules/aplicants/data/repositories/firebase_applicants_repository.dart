import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/aplications/data/mappers/application_mapper.dart';
import 'package:opti_job_app/modules/aplicants/repositories/applicants_repository.dart';

class FirebaseApplicantsRepository implements ApplicantsRepository {
  FirebaseApplicantsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Application>> getApplicationsForOffer({
    required int jobOfferId,
    required String companyUid,
  }) async {
    final collection = _firestore.collection('applications');

    Future<List<Application>> runQuery({
      required String offerField,
      required String companyField,
      bool includeCompany = true,
    }) async {
      var query = collection.where(offerField, isEqualTo: jobOfferId);
      if (includeCompany && companyUid.isNotEmpty) {
        query = query.where(companyField, isEqualTo: companyUid);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ApplicationMapper.fromFirestore(doc.data(), id: doc.id))
          .toList();
    }

    final primary = await runQuery(
      offerField: 'jobOfferId',
      companyField: 'companyUid',
    );
    if (primary.isNotEmpty) {
      return primary;
    }

    final fallbackResults = <String, Application>{};
    Future<void> merge(List<Application> apps) async {
      for (final app in apps) {
        if (app.id == null) continue;
        fallbackResults[app.id!] = app;
      }
    }

    await merge(
      await runQuery(offerField: 'job_offer_id', companyField: 'companyUid'),
    );
    await merge(
      await runQuery(offerField: 'jobOfferId', companyField: 'company_uid'),
    );
    await merge(
      await runQuery(offerField: 'job_offer_id', companyField: 'company_uid'),
    );

    if (fallbackResults.isEmpty) {
      await merge(
        await runQuery(
          offerField: 'jobOfferId',
          companyField: 'companyUid',
          includeCompany: false,
        ),
      );
      await merge(
        await runQuery(
          offerField: 'job_offer_id',
          companyField: 'companyUid',
          includeCompany: false,
        ),
      );
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
