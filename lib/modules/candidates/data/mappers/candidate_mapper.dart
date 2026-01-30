import 'package:opti_job_app/core/utils/firestore_utils.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

class CandidateMapper {
  static Candidate fromFirestore(Map<String, dynamic> data) {
    // Deep copy and transform Timestamps to ISO strings or DateTimes
    final transformed = _transformFirestoreData(data);
    return Candidate.fromJson(transformed);
  }

  static Map<String, dynamic> _transformFirestoreData(
    Map<String, dynamic> data,
  ) {
    return FirestoreUtils.transformFirestoreData(data);
  }
}
