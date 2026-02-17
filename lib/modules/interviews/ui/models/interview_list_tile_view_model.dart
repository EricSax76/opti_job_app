import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_status_view_model.dart';

class InterviewListTileViewModel extends Equatable {
  const InterviewListTileViewModel({
    required this.interviewId,
    required this.title,
    required this.messagePreview,
    required this.timeText,
    required this.status,
    this.scheduledLabel,
  });

  final String interviewId;
  final String title;
  final String messagePreview;
  final String timeText;
  final InterviewStatusViewModel status;
  final String? scheduledLabel;

  bool get isThreeLine => scheduledLabel != null;

  @override
  List<Object?> get props => [
    interviewId,
    title,
    messagePreview,
    timeText,
    status,
    scheduledLabel,
  ];
}
