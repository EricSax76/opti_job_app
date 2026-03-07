import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_actions_logic.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_chat_dialogs_controller.dart';

class InterviewChatActionsController {
  InterviewChatActionsController({required InterviewSessionCubit sessionCubit})
    : _sessionCubit = sessionCubit;

  final InterviewSessionCubit _sessionCubit;
  final TextEditingController messageController = TextEditingController();

  void dispose() {
    messageController.dispose();
  }

  void sendMessage() {
    final content = InterviewChatActionsLogic.normalizeMessageContent(
      messageController.text,
    );
    if (content == null) return;
    _sessionCubit.sendMessage(content);
    messageController.clear();
  }

  Future<void> proposeSlot(BuildContext context) async {
    final now = DateTime.now();
    final proposedDate = await InterviewChatDialogsController.pickProposedSlot(
      context: context,
      now: now,
    );
    if (proposedDate == null || !context.mounted) return;

    _sessionCubit.proposeSlot(
      proposedDate,
      InterviewChatActionsLogic.resolveTimeZone(now.timeZoneName),
    );
  }

  void respondToProposal(String proposalId, bool accept) {
    _sessionCubit.respondToSlot(proposalId, accept);
  }

  Future<void> startMeeting(BuildContext context) async {
    final link = await InterviewChatDialogsController.askForMeetingLink(
      context,
    );
    if (link == null || !context.mounted) return;
    _sessionCubit.startMeeting(link);
  }

  Future<void> completeInterview(BuildContext context) async {
    final notes = await InterviewChatDialogsController.askForCompletionNotes(
      context,
    );
    if (notes == null || !context.mounted) return;
    _sessionCubit.completeInterview(
      notes: notes.trim().isEmpty ? null : notes.trim(),
    );
  }

  Future<void> cancelInterview(BuildContext context) async {
    final reason =
        await InterviewChatDialogsController.askForCancellationReason(context);
    if (reason == null || !context.mounted) return;
    _sessionCubit.cancelInterview(
      reason: reason.trim().isEmpty ? null : reason.trim(),
    );
  }
}
