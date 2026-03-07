import 'package:opti_job_app/modules/interviews/models/interview.dart';

class InterviewActionPermissionsLogic {
  const InterviewActionPermissionsLogic._();

  static bool canCancel({
    required Interview interview,
    required String? currentUid,
  }) {
    final uid = _normalizeUid(currentUid);
    if (uid == null || isClosed(interview.status)) return false;
    return interview.participants.contains(uid);
  }

  static bool canComplete({
    required Interview interview,
    required String? currentUid,
  }) {
    final uid = _normalizeUid(currentUid);
    if (uid == null || isClosed(interview.status)) return false;
    return interview.companyUid == uid;
  }

  static bool isClosed(InterviewStatus status) {
    return status == InterviewStatus.cancelled ||
        status == InterviewStatus.completed;
  }

  static String? _normalizeUid(String? uid) {
    if (uid == null) return null;
    final normalized = uid.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
