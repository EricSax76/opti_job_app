import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/ai_generated_label.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_pre_apply_logic.dart';

class JobOfferPreApplyVerdictDialog extends StatelessWidget {
  const JobOfferPreApplyVerdictDialog({super.key, required this.result});

  final AiMatchResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final verdict = JobOfferPreApplyLogic.buildVerdict(score: result.score);
    final appearance = _appearanceFor(verdict.level, context);

    return AlertDialog(
      title: Text('Veredicto IA: ${result.score}/100'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiGeneratedLabel(compact: true),
            const SizedBox(height: uiSpacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(uiSpacing12),
              decoration: BoxDecoration(
                color: appearance.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(appearance.icon, color: appearance.iconColor),
                  const SizedBox(width: uiSpacing8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verdict.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: uiSpacing4),
                        Text(verdict.description),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (result.summary != null) ...[
              const SizedBox(height: uiSpacing12),
              Text(result.summary!),
            ],
            if (result.reasons.isNotEmpty) ...[
              const SizedBox(height: uiSpacing12),
              Text(
                'Puntos clave',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final reason in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8 - 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                ),
            ],
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: uiSpacing12),
              Text(
                'Recomendaciones',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final recommendation in result.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8 - 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                ),
            ],
            if (result.skillRoadmap.isNotEmpty) ...[
              const SizedBox(height: uiSpacing12),
              Text(
                'Mapa predictivo de carrera',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final step in result.skillRoadmap.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8 - 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          '${step.skill} (+${step.estimatedScoreDelta} pts): ${step.rationale}',
                        ),
                      ),
                    ],
                  ),
                ),
              if (result.projectedScore != null) ...[
                const SizedBox(height: uiSpacing8),
                Text(
                  'Score potencial con roadmap completado: ${result.projectedScore}/100',
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(verdict.actionLabel),
        ),
      ],
    );
  }

  _VerdictAppearance _appearanceFor(
    JobOfferApplicationVerdictLevel level,
    BuildContext context,
  ) {
    switch (level) {
      case JobOfferApplicationVerdictLevel.recommended:
        final color = Theme.of(context).colorScheme.tertiary;
        return _VerdictAppearance(
          icon: Icons.check_circle_outline,
          iconColor: color,
          backgroundColor: color.withValues(alpha: 0.12),
        );
      case JobOfferApplicationVerdictLevel.caution:
        final color = Theme.of(context).colorScheme.secondary;
        return _VerdictAppearance(
          icon: Icons.warning_amber_rounded,
          iconColor: color,
          backgroundColor: color.withValues(alpha: 0.14),
        );
      case JobOfferApplicationVerdictLevel.notRecommended:
        final color = Theme.of(context).colorScheme.error;
        return _VerdictAppearance(
          icon: Icons.do_not_disturb_on_outlined,
          iconColor: color,
          backgroundColor: color.withValues(alpha: 0.12),
        );
    }
  }
}

class _VerdictAppearance {
  const _VerdictAppearance({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
}
