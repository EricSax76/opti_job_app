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
    final query = await _firestore
        .collection('applications')
        .where('companyUid', isEqualTo: companyUid)
        .where('jobOfferId', isEqualTo: jobOfferId)
        .get();

    return query.docs
        .map((doc) => ApplicationMapper.fromFirestore(doc.data(), id: doc.id))
        .toList();
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
