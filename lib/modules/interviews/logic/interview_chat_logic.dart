import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';

class InterviewChatLogic {
  const InterviewChatLogic._();

  static String? resolveCurrentUid({
    required String? candidateUid,
    required String? companyUid,
  }) {
    final normalizedCandidate = _normalizeUid(candidateUid);
    if (normalizedCandidate != null) return normalizedCandidate;
    return _normalizeUid(companyUid);
  }

  static InterviewSessionLoaded? resolveLoadedState(
    InterviewSessionState state,
  ) {
    if (state is InterviewSessionLoaded) return state;
    if (state is InterviewSessionActionError) return state.previousState;
    return null;
  }

  static String? actionErrorMessage(InterviewSessionState state) {
    if (state is! InterviewSessionActionError) return null;
    final message = state.error.trim();
    if (message.isEmpty) return null;
    return message;
  }

  static String? _normalizeUid(String? uid) {
    if (uid == null) return null;
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
