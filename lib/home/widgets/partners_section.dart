import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class PartnersSection extends StatelessWidget {
  const PartnersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return LandingSectionReveal(
      child: Column(
        children: [
          SectionHeader(
            title: l10n.partnersTitle,
            titleFontSize: 22,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          const SizedBox(height: uiSpacing16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return LandingSectionReveal(
                  delay: landingStaggerDelay(i),
                  child: Container(
                    width: 100,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: uiSpacing8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(uiFieldRadius),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Partner ${i + 1}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
