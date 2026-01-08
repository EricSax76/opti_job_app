import 'package:flutter/material.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';
import 'package:opti_job_app/home/widgets/highlight_list.dart';

class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aiOptimizationTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.aiOptimizationDescription,
          style: TextStyle(color: muted, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        HighlightList(
          items: [
            l10n.aiFeatureAnalyzeProfiles,
            l10n.aiFeatureAutomateInterviews,
          ],
        ),
      ],
    );
  }
}
