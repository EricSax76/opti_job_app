import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';

class EvaluationRecommendationSelector extends StatelessWidget {
  const EvaluationRecommendationSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Recommendation selected;
  final ValueChanged<Recommendation> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Recommendation.values.map((recommendation) {
        final isSelected = selected == recommendation;
        return Padding(
          padding: const EdgeInsets.only(bottom: uiSpacing8),
          child: InkWell(
            onTap: () => onSelected(recommendation),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: uiSpacing16,
                vertical: uiSpacing12,
              ),
              backgroundColor: isSelected
                  ? _getColor(context, recommendation).withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
              borderColor: isSelected
                  ? _getColor(context, recommendation)
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: uiSpacing8,
              borderWidth: isSelected ? 2 : 1,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? _getColor(context, recommendation)
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: uiSpacing12),
                  Text(
                    _getLabel(recommendation),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? _getColor(context, recommendation)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildEmoji(recommendation),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColor(BuildContext context, Recommendation recommendation) {
    final scheme = Theme.of(context).colorScheme;
    switch (recommendation) {
      case Recommendation.strongYes:
        return scheme.tertiary.withValues(alpha: 0.85);
      case Recommendation.yes:
        return scheme.tertiary;
      case Recommendation.neutral:
        return scheme.primary;
      case Recommendation.no:
        return scheme.error;
      case Recommendation.strongNo:
        return scheme.error.withValues(alpha: 0.85);
    }
  }

  String _getLabel(Recommendation recommendation) {
    switch (recommendation) {
      case Recommendation.strongYes:
        return 'Strong Yes';
      case Recommendation.yes:
        return 'Yes';
      case Recommendation.neutral:
        return 'Neutral';
      case Recommendation.no:
        return 'No';
      case Recommendation.strongNo:
        return 'Strong No';
    }
  }

  Widget _buildEmoji(Recommendation recommendation) {
    String emoji;
    switch (recommendation) {
      case Recommendation.strongYes:
        emoji = '🤩';
        break;
      case Recommendation.yes:
        emoji = '🙂';
        break;
      case Recommendation.neutral:
        emoji = '😐';
        break;
      case Recommendation.no:
        emoji = '🙁';
        break;
      case Recommendation.strongNo:
        emoji = '😡';
        break;
    }
    return Text(emoji, style: const TextStyle(fontSize: 20));
  }
}
