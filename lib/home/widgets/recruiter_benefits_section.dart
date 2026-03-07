import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class RecruiterBenefitsSection extends StatelessWidget {
  const RecruiterBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= uiBreakpointTablet
        ? (width - uiSpacing24 * 2 - uiSpacing16) / 2
        : double.infinity;

    final benefits = [
      _Benefit(Icons.groups_outlined, l10n.recruiterBenefitTalentPool),
      _Benefit(Icons.view_kanban_outlined, l10n.recruiterBenefitAts),
      _Benefit(Icons.business_center_outlined, l10n.recruiterBenefitMultiCompany),
      _Benefit(Icons.admin_panel_settings_outlined, l10n.recruiterBenefitRbac),
      _Benefit(Icons.quiz_outlined, l10n.recruiterBenefitKnockout),
      _Benefit(Icons.assessment_outlined, l10n.recruiterBenefitEvaluations),
    ];

    return LandingSectionReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.recruiterBenefitsTitle,
            subtitle: l10n.recruiterBenefitsDescription,
            titleFontSize: 22,
            action: TextButton(
              onPressed: () => context.go('/para-recruiters'),
              child: Text(
                l10n.navRecruiters,
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
