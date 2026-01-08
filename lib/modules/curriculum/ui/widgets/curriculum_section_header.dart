import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_styles.dart';

class CurriculumSectionHeader extends StatelessWidget {
  const CurriculumSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cvMuted),
        ),
      ],
    );
  }
}
