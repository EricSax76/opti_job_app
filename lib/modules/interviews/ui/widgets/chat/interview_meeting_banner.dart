import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_meeting_actions_controller.dart';

class InterviewMeetingBanner extends StatelessWidget {
  const InterviewMeetingBanner({super.key, required this.meetingLink});

  final String meetingLink;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        uiSpacing12,
        uiSpacing8,
        uiSpacing12,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: uiSpacing8,
        horizontal: uiSpacing16,
      ),
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderColor: colorScheme.primary.withValues(alpha: 0.35),
      borderRadius: uiTileRadius,
      child: Row(
        children: [
          Icon(Icons.video_camera_front, color: colorScheme.primary),
          const SizedBox(width: uiSpacing8),
          Expanded(
            child: Text(
              'Videollamada en curso',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FilledButton(
            onPressed: () =>
                InterviewMeetingActionsController.openMeeting(meetingLink),
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }
}
