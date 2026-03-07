import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/app_footer.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/home/widgets/landing_app_bar.dart';
import 'package:opti_job_app/home/widgets/landing_drawer.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class ParaRecruitersScreen extends StatelessWidget {
  const ParaRecruitersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _Section(
        Icons.groups_outlined,
        l10n.paraRecruitersTalentPoolTitle,
        l10n.paraRecruitersTalentPoolDesc,
      ),
      _Section(
        Icons.view_kanban_outlined,
        l10n.paraRecruitersAtsTitle,
        l10n.paraRecruitersAtsDesc,
      ),
      _Section(
        Icons.admin_panel_settings_outlined,
        l10n.paraRecruitersRbacTitle,
        l10n.paraRecruitersRbacDesc,
      ),
      _Section(
        Icons.assessment_outlined,
        l10n.paraRecruitersEvaluationsTitle,
        l10n.paraRecruitersEvaluationsDesc,
      ),
      _Section(
        Icons.business_center_outlined,
        l10n.paraRecruitersMultiCompanyTitle,
        l10n.paraRecruitersMultiCompanyDesc,
      ),
    ];

    return CoreShell(
      variant: CoreShellVariant.public,
      backgroundColor: uiBackground,
      appBar: const LandingAppBar(),
      drawer: const LandingDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: uiBreakpointDesktop),
              child: Padding(
                padding: const EdgeInsets.all(uiSpacing24),
                child: Column(
                  children: [
                    LandingSectionReveal(
                      child: AppCard(
                        padding: const EdgeInsets.all(uiSpacing24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            uiLightHeaderGradientStart,
                            uiLightHeaderGradientEnd,
                          ],
                        ),
                        child: SectionHeader(
                          title: l10n.paraRecruitersTitle,
                          subtitle: l10n.paraRecruitersSubtitle,
                          titleFontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: uiSpacing32),
                    ...List.generate(sections.length, (i) {
                      final s = sections[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: uiSpacing16),
                        child: LandingSectionReveal(
                          delay: landingStaggerDelay(i),
                          child: LandingCardHover(
                            child: AppCard(
                              padding: const EdgeInsets.all(uiSpacing20),
                              borderRadius: uiTileRadius,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: uiAccentSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      s.icon,
                                      color: uiAccent,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: uiSpacing16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: uiSpacing4),
                                        Text(
                                          s.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: uiSpacing16),
                    LandingSectionReveal(
                      delay: landingStaggerDelay(sections.length),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.go('/recruiter-login'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: uiSpacing16,
                            ),
                          ),
                          child: Text(l10n.paraRecruitersCta),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}

class _Section {
  const _Section(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}
