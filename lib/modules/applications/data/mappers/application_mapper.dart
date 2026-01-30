import 'package:opti_job_app/core/utils/firestore_utils.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';

class ApplicationMapper {
  static Application fromFirestore(Map<String, dynamic> data, {String? id}) {
    final transformed = _transformFirestoreData(data);
    return Application.fromJson(transformed, id: id);
  }

  static Map<String, dynamic> _transformFirestoreData(
    Map<String, dynamic> data,
  ) {
    return FirestoreUtils.transformFirestoreData(data);
  }
}
