import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onCandidateLogin,
    required this.onCompanyLogin,
    required this.onRecruiterLogin,
    required this.onSeeOffers,
  });

  final VoidCallback onCandidateLogin;
  final VoidCallback onCompanyLogin;
  final VoidCallback onRecruiterLogin;
  final VoidCallback onSeeOffers;

  static final ButtonStyle _filledButtonStyle = FilledButton.styleFrom(
    backgroundColor: uiInk,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: uiSpacing20,
      vertical: uiSpacing12,
    ),
  );
  static final ButtonStyle _outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: uiInk,
    side: const BorderSide(color: uiBorder),
    padding: const EdgeInsets.symmetric(
      horizontal: uiSpacing20,
      vertical: uiSpacing12,
    ),
  );
  static final ButtonStyle _textButtonStyle = TextButton.styleFrom(
    foregroundColor: uiAccent,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width >= uiBreakpointDesktop
        ? 36.0
        : width >= uiBreakpointTablet
            ? 30.0
            : 24.0;

    return LandingSectionReveal(
      child: AppCard(
        padding: const EdgeInsets.all(uiSpacing24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [uiLightHeaderGradientStart, uiLightHeaderGradientEnd],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LandingSectionReveal(
              delay: landingStaggerDelay(0),
              child: InfoPill(
                icon: Icons.auto_awesome,
                label: l10n.heroBadge,
              ),
            ),
            const SizedBox(height: uiSpacing16),
            SectionHeader(
              tagline: l10n.heroTagline,
              title: l10n.heroTitle,
              subtitle: l10n.heroDescription,
              titleFontSize: titleSize,
            ),
            const SizedBox(height: uiSpacing24),
            LandingSectionReveal(
              delay: landingStaggerDelay(2),
              child: Wrap(
                spacing: uiSpacing12,
                runSpacing: uiSpacing12,
                children: [
                  FilledButton(
                    style: _filledButtonStyle,
                    onPressed: onCandidateLogin,
                    child: Text(l10n.heroCandidateCta),
                  ),
                  OutlinedButton(
                    style: _outlinedButtonStyle,
                    onPressed: onCompanyLogin,
                    child: Text(l10n.heroCompanyCta),
                  ),
                  OutlinedButton(
                    style: _outlinedButtonStyle,
                    onPressed: onRecruiterLogin,
                    child: Text(l10n.heroRecruiterCta),
                  ),
                  TextButton(
                    style: _textButtonStyle,
                    onPressed: onSeeOffers,
                    child: Text(l10n.heroOffersCta),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
