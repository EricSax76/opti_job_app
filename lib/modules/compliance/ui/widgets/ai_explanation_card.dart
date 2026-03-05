import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/ai_generated_label.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';

class AiExplanationCard extends StatelessWidget {
  const AiExplanationCard({super.key, required this.result, this.onOverride});

  final AiMatchResult result;
  final VoidCallback? onOverride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: uiSpacing12,
      borderColor: Theme.of(context).dividerColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: scheme.primary),
              const SizedBox(width: uiSpacing8),
              Expanded(
                child: Text(
                  'Razonamiento de la IA (AI Act Compliant)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (result.generatedAt != null)
                Text(
                  DateFormat('d MMM, HH:mm').format(result.generatedAt!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: uiSpacing8),
          const AiGeneratedLabel(compact: true),
          const SizedBox(height: uiSpacing12),
          Text(
            result.explanation,
            style: textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: uiSpacing16),
          _SkillsOverlapLegend(
            overlap:
                result.skillsOverlap ??
                const SkillsOverlap(matched: [], missing: [], adjacent: []),
          ),
          const Divider(height: uiSpacing24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puntuación IA: ${result.score}%',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Modelo: ${result.modelVersion}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (onOverride != null)
                OutlinedButton.icon(
                  onPressed: onOverride,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Corregir puntuación'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillsOverlapLegend extends StatelessWidget {
  const _SkillsOverlapLegend({required this.overlap});

  final SkillsOverlap overlap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverlapRow(
          label: 'Coincidencias',
          skills: overlap.matched,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        _OverlapRow(
          label: 'Relacionadas/Adyacentes',
          skills: overlap.adjacent,
          color: Theme.of(context).colorScheme.primary,
        ),
        _OverlapRow(
          label: 'Faltantes',
          skills: overlap.missing,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }
}

class _OverlapRow extends StatelessWidget {
  const _OverlapRow({
    required this.label,
    required this.skills,
    required this.color,
  });

  final String label;
  final List<String> skills;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();
    final tonedColor = color.withValues(alpha: 0.8);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: uiSpacing4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: uiSpacing4,
        runSpacing: uiSpacing4,
        children: [
          Text(
            '$label:',
            style: textTheme.labelSmall?.copyWith(
              color: tonedColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...skills.map(
            (skill) => InfoPill(
              label: skill,
              backgroundColor: tonedColor.withValues(alpha: 0.12),
              borderColor: tonedColor.withValues(alpha: 0.24),
              textColor: tonedColor,
            ),
          ),
        ],
      ),
    );
  }
}
