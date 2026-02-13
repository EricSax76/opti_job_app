import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
          FilledButton(onPressed: _openMeeting, child: const Text('Unirse')),
        ],
      ),
    );
  }

  Future<void> _openMeeting() async {
    final uri = Uri.tryParse(meetingLink);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
