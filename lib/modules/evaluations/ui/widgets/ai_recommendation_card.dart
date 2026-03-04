import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';

class AIRecommendationCard extends StatelessWidget {
  const AIRecommendationCard({
    super.key,
    required this.aiScore,
    required this.aiExplanation,
    required this.onOverride,
    this.isOverridden = false,
  });

  final double aiScore;
  final String aiExplanation;
  final VoidCallback onOverride;
  final bool isOverridden;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = scheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      backgroundColor: accent.withValues(alpha: 0.06),
      borderRadius: uiSpacing12,
      borderColor: accent.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: accent),
              const SizedBox(width: uiSpacing8),
              Text(
                'AI Recommendation',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const Spacer(),
              if (isOverridden)
                InfoPill(
                  label: 'Overridden',
                  icon: Icons.edit_outlined,
                  backgroundColor: scheme.secondary.withValues(alpha: 0.14),
                  borderColor: scheme.secondary.withValues(alpha: 0.3),
                  textColor: scheme.secondary,
                  iconColor: scheme.secondary,
                ),
            ],
          ),
          const SizedBox(height: uiSpacing12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(uiSpacing12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  aiScore.toStringAsFixed(1),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: uiSpacing16),
              Expanded(
                child: Text(
                  aiExplanation,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: uiSpacing16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOverride,
              icon: const Icon(Icons.edit, size: 16),
              label: Text(isOverridden ? 'Edit Override' : 'Override AI Score'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
