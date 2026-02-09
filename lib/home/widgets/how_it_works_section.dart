import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final steps = [
      l10n.howItWorksStepRegister,
      l10n.howItWorksStepPublish,
      l10n.howItWorksStepAiMatch,
      l10n.howItWorksStepSchedule,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.howItWorksTitle,
          subtitle: l10n.howItWorksDescription,
          titleFontSize: 22,
        ),
        const SizedBox(height: uiSpacing16),
        Column(
          children: List.generate(steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: uiSpacing8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: uiSpacing16,
                  vertical: uiSpacing12,
                ),
                borderRadius: uiTileRadius,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: uiAccentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: uiInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: uiSpacing12),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: const TextStyle(color: uiInk, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
