import 'package:url_launcher/url_launcher.dart';

class InterviewMeetingActionsController {
  const InterviewMeetingActionsController._();

  static Future<void> openMeeting(String meetingLink) async {
    final uri = Uri.tryParse(meetingLink);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
