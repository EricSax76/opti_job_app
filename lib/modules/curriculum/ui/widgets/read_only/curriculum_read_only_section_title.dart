import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class CurriculumReadOnlySectionTitle extends StatelessWidget {
  const CurriculumReadOnlySectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: uiSpacing8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: uiMuted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
