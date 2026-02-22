import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';

class CurriculumReadOnlySkillsCard extends StatelessWidget {
  const CurriculumReadOnlySkillsCard({super.key, required this.skills});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Wrap(
        spacing: uiSpacing8,
        runSpacing: uiSpacing8,
        children: [for (final skill in skills) InfoPill(label: skill)],
      ),
    );
  }
}
