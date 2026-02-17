import 'package:intl/intl.dart';
import 'package:opti_job_app/modules/interviews/models/interview_message.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_message_bubble_view_model.dart';

class InterviewMessageBubbleLogic {
  const InterviewMessageBubbleLogic._();

  static InterviewMessageBubbleViewModel buildViewModel({
    required InterviewMessage message,
    required String? currentUid,
  }) {
    return InterviewMessageBubbleViewModel(
      content: message.content,
      isSystem: message.isSystem,
      isProposal: message.isProposal,
      showProposalActions: _showProposalActions(
        message: message,
        currentUid: currentUid,
      ),
      createdAtText: _safeFormatDateTime(message.createdAt, 'jm'),
      proposalDateText: message.metadata?.proposedAt == null
          ? null
          : _safeFormatDateTime(
              message.metadata!.proposedAt!,
              'EEEE d MMM, h:mm a',
            ),
    );
  }

  static bool _showProposalActions({
    required InterviewMessage message,
    required String? currentUid,
  }) {
    if (!message.isProposal) return false;

    final viewerUid = currentUid?.trim();
    if (viewerUid == null || viewerUid.isEmpty) return true;
    return message.senderUid.trim() != viewerUid;
  }

  static String _safeFormatDateTime(DateTime date, String pattern) {
    try {
      return DateFormat(pattern).format(date);
    } catch (_) {
      return date.toLocal().toIso8601String();
    }
  }
}
