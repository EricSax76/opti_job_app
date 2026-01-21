import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/widgets/highlight_list.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.aiOptimizationTitle,
          subtitle: l10n.aiOptimizationDescription,
          titleFontSize: 22,
        ),
        const SizedBox(height: uiSpacing16),
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
