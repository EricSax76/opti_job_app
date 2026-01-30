import 'package:opti_job_app/core/utils/firestore_utils.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumMapper {
  static Curriculum fromFirestore(Map<String, dynamic> data) {
    final transformed = _transformFirestoreData(data);
    return Curriculum.fromJson(transformed);
  }

  static Map<String, dynamic> _transformFirestoreData(
    Map<String, dynamic> data,
  ) {
    return FirestoreUtils.transformFirestoreData(data);
  }
}
