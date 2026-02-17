import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/interviews/logic/interview_chat_actions_logic.dart';

void main() {
  group('InterviewChatActionsLogic', () {
    test('normalizeMessageContent trims and validates content', () {
      expect(
        InterviewChatActionsLogic.normalizeMessageContent('  Hola  '),
        'Hola',
      );
      expect(InterviewChatActionsLogic.normalizeMessageContent('   '), isNull);
    });

    test('normalizeMeetingLink trims and validates link', () {
      expect(
        InterviewChatActionsLogic.normalizeMeetingLink('  https://meet.link  '),
        'https://meet.link',
      );
      expect(InterviewChatActionsLogic.normalizeMeetingLink(''), isNull);
      expect(InterviewChatActionsLogic.normalizeMeetingLink(null), isNull);
    });

    test('buildSlotPickerViewModel provides expected defaults', () {
      final now = DateTime.utc(2026, 2, 17, 12);
      final viewModel = InterviewChatActionsLogic.buildSlotPickerViewModel(now);

      expect(viewModel.firstDate, now);
      expect(viewModel.lastDate, now.add(const Duration(days: 30)));
      expect(viewModel.initialDate, now.add(const Duration(days: 1)));
      expect(viewModel.initialTime, const TimeOfDay(hour: 10, minute: 0));
    });

    test('buildProposedDate composes date and time', () {
      final proposedDate = InterviewChatActionsLogic.buildProposedDate(
        date: DateTime.utc(2026, 2, 20),
        time: const TimeOfDay(hour: 14, minute: 45),
      );

      expect(proposedDate.year, 2026);
      expect(proposedDate.month, 2);
      expect(proposedDate.day, 20);
      expect(proposedDate.hour, 14);
      expect(proposedDate.minute, 45);
    });

    test('resolveTimeZone falls back to UTC', () {
      expect(InterviewChatActionsLogic.resolveTimeZone('  CET '), 'CET');
      expect(InterviewChatActionsLogic.resolveTimeZone(''), 'UTC');
      expect(InterviewChatActionsLogic.resolveTimeZone(null), 'UTC');
    });

    test('buildMeetingLinkDialogViewModel exposes default values', () {
      final viewModel =
          InterviewChatActionsLogic.buildMeetingLinkDialogViewModel();

      expect(viewModel.title, 'Iniciar Videollamada');
      expect(viewModel.fieldLabel, 'Enlace de la reunión');
      expect(viewModel.cancelLabel, 'Cancelar');
      expect(viewModel.confirmLabel, 'Iniciar');
      expect(viewModel.initialValue, 'https://meet.google.com/new');
    });
  });
}
