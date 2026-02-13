import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';

class InterviewChatActionsController {
  InterviewChatActionsController({required InterviewSessionCubit sessionCubit})
    : _sessionCubit = sessionCubit;

  static const _defaultMeetingUrl = 'https://meet.google.com/new';

  final InterviewSessionCubit _sessionCubit;
  final TextEditingController messageController = TextEditingController();

  void dispose() {
    messageController.dispose();
  }

  void sendMessage() {
    final content = messageController.text.trim();
    if (content.isEmpty) return;
    _sessionCubit.sendMessage(content);
    messageController.clear();
  }

  Future<void> proposeSlot(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !context.mounted) return;

    final proposedDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    _sessionCubit.proposeSlot(proposedDate, DateTime.now().timeZoneName);
  }

  Future<void> startMeeting(BuildContext context) async {
    final link = await _askForMeetingLink(context);
    if (link == null || !context.mounted) return;
    _sessionCubit.startMeeting(link);
  }

  Future<String?> _askForMeetingLink(BuildContext context) async {
    final controller = TextEditingController(text: _defaultMeetingUrl);

    try {
      final link = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Iniciar Videollamada'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Enlace de la reunión'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Iniciar'),
            ),
          ],
        ),
      );

      final normalized = link?.trim();
      if (normalized == null || normalized.isEmpty) return null;
      return normalized;
    } finally {
      controller.dispose();
    }
  }
}
