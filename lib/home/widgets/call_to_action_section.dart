import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class CallToActionSection extends StatelessWidget {
  const CallToActionSection({
    super.key,
    required this.onCompanyRegister,
    required this.onCandidateRegister,
    required this.onSeeOffers,
  });

  final VoidCallback onCompanyRegister;
  final VoidCallback onCandidateRegister;
  final VoidCallback onSeeOffers;

  static final ButtonStyle _filledButtonStyle = FilledButton.styleFrom(
    backgroundColor: uiInk,
    foregroundColor: Colors.white,
  );
  static final ButtonStyle _outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: uiInk,
    side: const BorderSide(color: uiBorder),
  );
  static final ButtonStyle _textButtonStyle = TextButton.styleFrom(
    foregroundColor: uiAccent,
  );

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
                style: _filledButtonStyle,
                onPressed: onCompanyRegister,
                child: Text(l10n.ctaCompanyRegister),
              ),
              OutlinedButton(
                style: _outlinedButtonStyle,
                onPressed: onCandidateRegister,
                child: Text(l10n.ctaCandidateRegister),
              ),
              TextButton(
                style: _textButtonStyle,
                onPressed: onSeeOffers,
                child: Text(l10n.ctaOffers),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
