import 'package:intl/intl.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_status_logic.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_list_tile_view_model.dart';

class InterviewListTileLogic {
  const InterviewListTileLogic._();

  static InterviewListTileViewModel buildViewModel({
    required Interview interview,
    required bool isCompany,
  }) {
    final date = interview.lastMessage?.createdAt ?? interview.updatedAt;
    final scheduledLabel =
        interview.status == InterviewStatus.scheduled &&
            interview.scheduledAt != null
        ? _safeFormatDateTime(interview.scheduledAt!, 'MMM d, h:mm a')
        : null;

    return InterviewListTileViewModel(
      interviewId: interview.id,
      title: isCompany
          ? 'Candidato (ID: ${_shortUid(interview.candidateUid)})'
          : 'Empresa (ID: ${_shortUid(interview.companyUid)})',
      messagePreview: interview.lastMessage?.content ?? 'Nueva entrevista',
      timeText: _safeFormatDateTime(date, 'jm'),
      status: InterviewStatusLogic.buildViewModel(interview.status),
      scheduledLabel: scheduledLabel,
    );
  }

  static String _shortUid(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return 'N/A';
    if (trimmed.length <= 5) return trimmed;
    return '${trimmed.substring(0, 5)}...';
  }

  static String _safeFormatDateTime(DateTime date, String pattern) {
    try {
      return DateFormat(pattern).format(date);
    } catch (_) {
      return date.toLocal().toIso8601String();
    }
  }
}
