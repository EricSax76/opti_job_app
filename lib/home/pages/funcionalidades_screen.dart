import 'package:flutter/material.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/app_footer.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/home/widgets/landing_app_bar.dart';
import 'package:opti_job_app/home/widgets/landing_drawer.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class FuncionalidadesScreen extends StatelessWidget {
  const FuncionalidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= uiBreakpointDesktop
        ? 3
        : width >= uiBreakpointTablet
            ? 2
            : 1;

    final categories = [
      _Category(l10n.funcCategoryCandidates, [
        _Feature(Icons.search_outlined, l10n.funcSmartSearch, l10n.funcSmartSearchDesc),
        _Feature(Icons.description_outlined, l10n.funcCvManagement, l10n.funcCvManagementDesc),
        _Feature(Icons.track_changes_outlined, l10n.funcApplicationTracking, l10n.funcApplicationTrackingDesc),
      ]),
      _Category(l10n.funcCategoryCompanies, [
        _Feature(Icons.post_add_outlined, l10n.funcOfferPublishing, l10n.funcOfferPublishingDesc),
        _Feature(Icons.view_kanban_outlined, l10n.funcAtsPipeline, l10n.funcAtsPipelineDesc),
        _Feature(Icons.event_available_outlined, l10n.funcInterviewScheduling, l10n.funcInterviewSchedulingDesc),
      ]),
      _Category(l10n.funcCategoryRecruiters, [
        _Feature(Icons.people_outline, l10n.funcTeamManagement, l10n.funcTeamManagementDesc),
        _Feature(Icons.groups_outlined, l10n.funcTalentPool, l10n.funcTalentPoolDesc),
      ]),
      _Category(l10n.funcCategoryAi, [
        _Feature(Icons.auto_awesome_outlined, l10n.funcProfileAnalysis, l10n.funcProfileAnalysisDesc),
        _Feature(Icons.smart_toy_outlined, l10n.aiFeatureSmartMatching, l10n.funcSmartSearchDesc),
      ]),
      _Category(l10n.funcCategoryCompliance, [
        _Feature(Icons.shield_outlined, l10n.funcGdprCompliance, l10n.funcGdprComplianceDesc),
      ]),
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
                          title: l10n.funcionalidadesTitle,
                          subtitle: l10n.funcionalidadesSubtitle,
                          titleFontSize: 28,
                          crossAxisAlignment: CrossAxisAlignment.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: uiSpacing32),
                    ...categories.asMap().entries.map((entry) {
                      final catIndex = entry.key;
                      final cat = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: uiSpacing32),
                        child: LandingSectionReveal(
                          delay: landingStaggerDelay(catIndex),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: cat.title,
                                titleFontSize: 20,
                              ),
                              const SizedBox(height: uiSpacing16),
                              _FeatureGrid(
                                features: cat.features,
                                crossAxisCount: crossAxisCount,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.features,
    required this.crossAxisCount,
  });

  final List<_Feature> features;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: uiSpacing16,
      runSpacing: uiSpacing16,
      children: features.asMap().entries.map((entry) {
        final i = entry.key;
        final f = entry.value;
        return LandingSectionReveal(
          delay: landingStaggerDelay(i),
          child: SizedBox(
            width: crossAxisCount == 1
                ? double.infinity
                : crossAxisCount == 2
                    ? (MediaQuery.sizeOf(context).width - uiSpacing24 * 2 - uiSpacing16) / 2
                    : (MediaQuery.sizeOf(context).width - uiSpacing24 * 2 - uiSpacing16 * 2) / 3,
            child: LandingCardHover(
              child: AppCard(
                padding: const EdgeInsets.all(uiSpacing16),
                borderRadius: uiTileRadius,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: uiAccentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(f.icon, color: uiAccent, size: 22),
                    ),
                    const SizedBox(height: uiSpacing12),
                    Text(
                      f.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: uiSpacing4),
                    Text(
                      f.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Category {
  const _Category(this.title, this.features);
  final String title;
  final List<_Feature> features;
}

class _Feature {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}
