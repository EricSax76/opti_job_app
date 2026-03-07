import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/home/widgets/highlight_list.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LandingSectionReveal(
      child: AppCard(
        padding: const EdgeInsets.all(uiSpacing24),
        backgroundColor: uiAccentSoft,
        borderRadius: uiTileRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: uiAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shield_outlined,
                    color: uiAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: uiSpacing16),
                Expanded(
                  child: SectionHeader(
                    title: l10n.trustSectionTitle,
                    subtitle: l10n.trustSectionDescription,
                    titleFontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: uiSpacing16),
            HighlightList(
              items: [
                l10n.trustGdpr,
                l10n.trustConsent,
                l10n.trustDataPrivacy,
                l10n.trustAuditTrail,
                l10n.trustAiTransparency,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
