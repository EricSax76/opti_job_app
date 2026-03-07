import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/utils/landing_motion.dart';
import 'package:opti_job_app/l10n/app_localizations.dart';

class PlatformStatsSection extends StatelessWidget {
  const PlatformStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= uiBreakpointTablet ? 160.0 : (width - uiSpacing24 * 2 - uiSpacing16) / 2;

    final stats = [
      _Stat(Icons.business_outlined, 500, l10n.statsCompaniesLabel),
      _Stat(Icons.person_outline, 10000, l10n.statsCandidatesLabel),
      _Stat(Icons.work_outline, 2000, l10n.statsOffersLabel),
      _Stat(Icons.video_camera_front_outlined, 5000, l10n.statsInterviewsLabel),
    ];

    return LandingSectionReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.statsTitle,
            titleFontSize: 22,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          const SizedBox(height: uiSpacing16),
          Center(
            child: Wrap(
              spacing: uiSpacing16,
              runSpacing: uiSpacing16,
              alignment: WrapAlignment.center,
              children: List.generate(stats.length, (i) {
                final s = stats[i];
                return LandingSectionReveal(
                  delay: landingStaggerDelay(i),
                  child: SizedBox(
                    width: cardWidth,
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: uiSpacing20,
                        horizontal: uiSpacing12,
                      ),
                      borderRadius: uiTileRadius,
                      child: Column(
                        children: [
                          Icon(s.icon, color: uiAccent, size: 28),
                          const SizedBox(height: uiSpacing8),
                          _AnimatedCounter(target: s.value),
                          const SizedBox(height: uiSpacing4),
                          Text(
                            s.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: uiMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  const _AnimatedCounter({required this.target});

  final int target;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);

    if (disabled) {
      return Text(
        _formatNumber(target),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: uiInk,
        ),
      );
    }

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: uiDurationSlow * 2,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          _formatNumber(value),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: uiInk,
          ),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      final formatted = k == k.truncateToDouble()
          ? '${k.toInt()}.000'
          : k.toStringAsFixed(1);
      return '$formatted+';
    }
    return '$n+';
  }
}

class _Stat {
  const _Stat(this.icon, this.value, this.label);
  final IconData icon;
  final int value;
  final String label;
}
