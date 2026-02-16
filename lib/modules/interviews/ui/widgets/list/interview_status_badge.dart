import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/interviews/models/interview.dart';

class InterviewStatusBadge extends StatelessWidget {
  const InterviewStatusBadge({super.key, required this.status});

  final InterviewStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, String) _styleFor(InterviewStatus status) {
    return switch (status) {
      InterviewStatus.scheduling => (Colors.orange, 'Agendando'),
      InterviewStatus.scheduled => (Colors.blue, 'Agendada'),
      InterviewStatus.completed => (Colors.green, 'Completada'),
      InterviewStatus.cancelled => (Colors.red, 'Cancelada'),
    };
  }
}
