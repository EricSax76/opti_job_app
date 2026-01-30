import 'package:opti_job_app/core/utils/firestore_utils.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class JobOfferMapper {
  static JobOffer fromFirestore(Map<String, dynamic> data) {
    final transformed = _transformFirestoreData(data);
    return JobOffer.fromJson(transformed);
  }

  static Map<String, dynamic> _transformFirestoreData(
    Map<String, dynamic> data,
  ) {
    return FirestoreUtils.transformFirestoreData(data);
  }
}
