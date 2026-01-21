import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class JobOfferMapper {
  static JobOffer fromFirestore(Map<String, dynamic> data) {
    final transformed = _transformFirestoreData(data);
    return JobOffer.fromJson(transformed);
  }

  static Map<String, dynamic> _transformFirestoreData(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _transformFirestoreData(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _transformFirestoreData(item);
          }
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
