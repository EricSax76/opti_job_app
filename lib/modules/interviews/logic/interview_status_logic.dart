import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/interviews/models/interview.dart';
import 'package:opti_job_app/modules/interviews/ui/models/interview_status_view_model.dart';

class InterviewStatusLogic {
  const InterviewStatusLogic._();

  static InterviewStatusViewModel buildViewModel(InterviewStatus status) {
    return switch (status) {
      InterviewStatus.scheduling => const InterviewStatusViewModel(
        label: 'Agendando',
        color: Colors.orange,
      ),
      InterviewStatus.scheduled => const InterviewStatusViewModel(
        label: 'Agendada',
        color: Colors.blue,
      ),
      InterviewStatus.completed => const InterviewStatusViewModel(
        label: 'Completada',
        color: Colors.green,
      ),
      InterviewStatus.cancelled => const InterviewStatusViewModel(
        label: 'Cancelada',
        color: Colors.red,
      ),
    };
  }
}
