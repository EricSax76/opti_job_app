import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumMapper {
  static Curriculum fromFirestore(Map<String, dynamic> data) {
    final transformed = _transformFirestoreData(data);
    return Curriculum.fromJson(transformed);
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
