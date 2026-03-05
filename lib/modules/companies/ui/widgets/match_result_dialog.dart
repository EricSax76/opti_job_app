import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/ai_generated_label.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';

class MatchResultDialog extends StatelessWidget {
  const MatchResultDialog({super.key, required this.result});
  final AiMatchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Match (Empresa): ${result.score}/100'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiGeneratedLabel(compact: true),
            const SizedBox(height: uiSpacing12),
            if (result.summary != null) ...[
              Text(result.summary!),
              const SizedBox(height: uiSpacing12),
            ],
            if (result.reasons.isNotEmpty) ...[
              Text(
                'Motivos',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final reason in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8),
                  child: _BulletText(
                    icon: Icons.check_circle_outline,
                    text: reason,
                  ),
                ),
              const SizedBox(height: uiSpacing8),
            ],
            if (result.recommendations.isNotEmpty) ...[
              Text(
                'Recomendaciones',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final recommendation in result.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8),
                  child: _BulletText(
                    icon: Icons.tips_and_updates_outlined,
                    text: recommendation,
                  ),
                ),
            ],
            if (result.skillRoadmap.isNotEmpty) ...[
              const SizedBox(height: uiSpacing8),
              Text(
                'Roadmap de skills adyacentes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final step in result.skillRoadmap.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8),
                  child: _BulletText(
                    icon: Icons.route_outlined,
                    text:
                        '${step.skill} (+${step.estimatedScoreDelta} pts): ${step.rationale}',
                  ),
                ),
              if (result.projectedScore != null)
                Text(
                  'Score proyectado al completar roadmap: ${result.projectedScore}/100',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            if (result.summary == null &&
                result.reasons.isEmpty &&
                result.recommendations.isEmpty &&
                result.skillRoadmap.isEmpty)
              const Text('No hay detalles adicionales disponibles.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: uiSpacing16 + 2),
        const SizedBox(width: uiSpacing8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
