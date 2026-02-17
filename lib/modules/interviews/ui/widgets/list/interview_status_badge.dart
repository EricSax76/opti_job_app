import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/interviews/ui/models/interview_status_view_model.dart';

class InterviewStatusBadge extends StatelessWidget {
  const InterviewStatusBadge({super.key, required this.viewModel});

  final InterviewStatusViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: uiSpacing8,
        vertical: uiSpacing4,
      ),
      decoration: BoxDecoration(
        color: viewModel.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(uiSpacing12),
        border: Border.all(color: viewModel.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        viewModel.label,
        style: TextStyle(
          color: viewModel.color,
          fontSize: uiSpacing8 + 3,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
