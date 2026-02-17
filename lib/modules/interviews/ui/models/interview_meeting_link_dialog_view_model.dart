import 'package:equatable/equatable.dart';

class InterviewMeetingLinkDialogViewModel extends Equatable {
  const InterviewMeetingLinkDialogViewModel({
    required this.title,
    required this.fieldLabel,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.initialValue,
  });

  final String title;
  final String fieldLabel;
  final String cancelLabel;
  final String confirmLabel;
  final String initialValue;

  @override
  List<Object> get props => [
    title,
    fieldLabel,
    cancelLabel,
    confirmLabel,
    initialValue,
  ];
}
