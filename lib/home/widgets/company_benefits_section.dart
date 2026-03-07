import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class CompanyBenefitsSection extends StatelessWidget {
  const CompanyBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= uiBreakpointTablet
        ? (width - uiSpacing24 * 2 - uiSpacing16) / 2
        : double.infinity;

    final benefits = [
      _Benefit(Icons.post_add_outlined, l10n.companyBenefitPublishOffers),
      _Benefit(Icons.people_alt_outlined, l10n.companyBenefitApplicantManagement),
      _Benefit(Icons.bar_chart_outlined, l10n.companyBenefitAnalytics),
      _Benefit(Icons.verified_user_outlined, l10n.companyBenefitCompliance),
      _Benefit(Icons.auto_awesome_outlined, l10n.companyBenefitAiJobOffers),
      _Benefit(Icons.event_available_outlined, l10n.companyBenefitInterviews),
    ];

    return LandingSectionReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.companyBenefitsTitle,
            subtitle: l10n.companyBenefitsDescription,
            titleFontSize: 22,
            action: TextButton(
              onPressed: () => context.go('/para-empresas'),
              child: Text(
                l10n.navCompanies,
                style: const TextStyle(color: uiAccent),
              ),
            ),
          ),
          const SizedBox(height: uiSpacing16),
          Wrap(
            spacing: uiSpacing16,
            runSpacing: uiSpacing16,
            children: List.generate(benefits.length, (i) {
              final b = benefits[i];
              return LandingSectionReveal(
                delay: landingStaggerDelay(i),
                child: SizedBox(
                  width: cardWidth.clamp(0, 560).toDouble(),
                  child: LandingCardHover(
                    child: AppCard(
                      padding: const EdgeInsets.all(uiSpacing16),
                      borderRadius: uiTileRadius,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: uiAccentSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(b.icon, color: uiAccent, size: 22),
                          ),
                          const SizedBox(width: uiSpacing12),
                          Expanded(
                            child: Text(
                              b.label,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Benefit {
  const _Benefit(this.icon, this.label);
  final IconData icon;
  final String label;
}
