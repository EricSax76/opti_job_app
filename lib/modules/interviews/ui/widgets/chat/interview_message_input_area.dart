import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class InterviewMessageInputArea extends StatelessWidget {
  const InterviewMessageInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onProposeSlot,
    required this.onStartMeeting,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final Future<void> Function() onProposeSlot;
  final Future<void> Function() onStartMeeting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(uiSpacing8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: uiSpacing12,
                    vertical: uiSpacing8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(uiFieldRadius),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(uiFieldRadius),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(uiFieldRadius),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: onProposeSlot,
            ),
            IconButton(
              icon: const Icon(Icons.video_call),
              onPressed: onStartMeeting,
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: onSend),
          ],
        ),
      ),
    );
  }
}
