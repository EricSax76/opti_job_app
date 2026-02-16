import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class CurriculumReadOnlyTextCard extends StatelessWidget {
  const CurriculumReadOnlyTextCard({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Text(text, style: style),
    );
  }
}
