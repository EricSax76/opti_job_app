import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/interviews/ui/controllers/interview_meeting_actions_controller.dart';

class InterviewMeetingBanner extends StatelessWidget {
  const InterviewMeetingBanner({super.key, required this.meetingLink});

  final String meetingLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.video_camera_front, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Videollamada en curso',
              style: TextStyle(
                color: Colors.blue.shade900,
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
