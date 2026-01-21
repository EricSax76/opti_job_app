import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class CallToActionSection extends StatelessWidget {
  const CallToActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing24),
      backgroundColor: uiAccentSoft,
      borderRadius: uiTileRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.ctaTitle,
            subtitle: l10n.ctaDescription,
            titleFontSize: 22,
          ),
          const SizedBox(height: uiSpacing16),
          Wrap(
            spacing: uiSpacing12,
            runSpacing: uiSpacing12,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: uiInk,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.go('/companyregister'),
                child: Text(l10n.ctaCompanyRegister),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: uiInk,
                  side: const BorderSide(color: uiBorder),
                ),
                onPressed: () => context.go('/candidateregister'),
                child: Text(l10n.ctaCandidateRegister),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: uiAccent),
                onPressed: () => context.go('/job-offer'),
                child: Text(l10n.ctaOffers),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
