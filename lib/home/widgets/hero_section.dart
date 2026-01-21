import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key, required this.onSeeOffers});

  final VoidCallback onSeeOffers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            tagline: l10n.heroTagline,
            title: l10n.heroTitle,
            subtitle: l10n.heroDescription,
            titleFontSize: 30,
          ),
          const SizedBox(height: uiSpacing24),
          Wrap(
            spacing: uiSpacing12,
            runSpacing: uiSpacing12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: uiInk,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: uiSpacing20,
                    vertical: uiSpacing12,
                  ),
                ),
                onPressed: () => context.go('/CandidateLogin'),
                child: Text(l10n.heroCandidateCta),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: uiInk,
                  side: const BorderSide(color: uiBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: uiSpacing20,
                    vertical: uiSpacing12,
                  ),
                ),
                onPressed: () => context.go('/CompanyLogin'),
                child: Text(l10n.heroCompanyCta),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: uiAccent),
                onPressed: onSeeOffers,
                child: Text(l10n.heroOffersCta),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
