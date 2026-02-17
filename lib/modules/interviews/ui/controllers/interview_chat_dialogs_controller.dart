import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_actions_logic.dart';

class InterviewChatDialogsController {
  const InterviewChatDialogsController._();

  static Future<DateTime?> pickProposedSlot({
    required BuildContext context,
    required DateTime now,
  }) async {
    final viewModel = InterviewChatActionsLogic.buildSlotPickerViewModel(now);

    final date = await showDatePicker(
      context: context,
      firstDate: viewModel.firstDate,
      lastDate: viewModel.lastDate,
      initialDate: viewModel.initialDate,
    );
    if (date == null || !context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: viewModel.initialTime,
    );
    if (time == null || !context.mounted) return null;

    return InterviewChatActionsLogic.buildProposedDate(date: date, time: time);
  }

  static Future<String?> askForMeetingLink(BuildContext context) async {
    final viewModel =
        InterviewChatActionsLogic.buildMeetingLinkDialogViewModel();
    final controller = TextEditingController(text: viewModel.initialValue);

    try {
      final link = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(viewModel.title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: viewModel.fieldLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(viewModel.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(viewModel.confirmLabel),
            ),
          ],
        ),
      );

      return InterviewChatActionsLogic.normalizeMeetingLink(link);
    } finally {
      controller.dispose();
    }
  }
}
