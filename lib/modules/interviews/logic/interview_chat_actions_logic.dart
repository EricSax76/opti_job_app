import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_meeting_link_dialog_view_model.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_slot_picker_view_model.dart';

class InterviewChatActionsLogic {
  const InterviewChatActionsLogic._();

  static const _defaultMeetingUrl = 'https://meet.google.com/new';
  static const _defaultInitialSlotDaysAhead = 1;
  static const _defaultMaxSlotDaysAhead = 30;
  static const _defaultInitialSlotTime = TimeOfDay(hour: 10, minute: 0);

  static InterviewSlotPickerViewModel buildSlotPickerViewModel(DateTime now) {
    return InterviewSlotPickerViewModel(
      firstDate: now,
      lastDate: now.add(const Duration(days: _defaultMaxSlotDaysAhead)),
      initialDate: now.add(const Duration(days: _defaultInitialSlotDaysAhead)),
      initialTime: _defaultInitialSlotTime,
    );
  }

  static DateTime buildProposedDate({
    required DateTime date,
    required TimeOfDay time,
  }) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static String? normalizeMessageContent(String rawContent) {
    final normalized = rawContent.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }

  static String? normalizeMeetingLink(String? rawLink) {
    final normalized = rawLink?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static String resolveTimeZone(String? rawTimeZone) {
    final normalized = rawTimeZone?.trim() ?? '';
    if (normalized.isEmpty) return 'UTC';
    return normalized;
  }

  static InterviewMeetingLinkDialogViewModel buildMeetingLinkDialogViewModel() {
    return const InterviewMeetingLinkDialogViewModel(
      title: 'Iniciar Videollamada',
      fieldLabel: 'Enlace de la reunión',
      cancelLabel: 'Cancelar',
      confirmLabel: 'Iniciar',
      initialValue: _defaultMeetingUrl,
    );
  }
}
