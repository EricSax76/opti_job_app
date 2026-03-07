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

  static Future<String?> askForCompletionNotes(BuildContext context) {
    return _askForOptionalText(
      context: context,
      title: 'Completar entrevista',
      fieldLabel: 'Notas (opcional)',
      hintText: 'Resumen de la entrevista',
      confirmLabel: 'Completar',
    );
  }

  static Future<String?> askForCancellationReason(BuildContext context) {
    return _askForOptionalText(
      context: context,
      title: 'Cancelar entrevista',
      fieldLabel: 'Motivo (opcional)',
      hintText: 'Razón de la cancelación',
      confirmLabel: 'Confirmar cancelación',
    );
  }

  static Future<String?> _askForOptionalText({
    required BuildContext context,
    required String title,
    required String fieldLabel,
    required String hintText,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    try {
      final value = await showDialog<String?>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: fieldLabel,
              hintText: hintText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      if (value == null) return null;
      return value.trim();
    } finally {
      controller.dispose();
    }
  }
}
