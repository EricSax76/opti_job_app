import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class InterviewListTileTitle extends StatelessWidget {
  const InterviewListTileTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: uiSpacing12 + 2,
    );
    return Text(title, style: style);
  }
}
