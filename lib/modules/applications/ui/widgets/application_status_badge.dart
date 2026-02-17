import 'package:flutter/material.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/applications/models/application_status.dart';

class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status});

  /// Factory constructor to create from a string, handling parsing internally.
  factory ApplicationStatusBadge.fromString(String? statusString) {
    return ApplicationStatusBadge(
      status: ApplicationStatus.fromString(statusString),
    );
  }

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return InfoPill(
      label: status.label,
      backgroundColor: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color,
    );
  }
}
