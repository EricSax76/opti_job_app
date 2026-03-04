import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';

class EvaluationSummaryCard extends StatelessWidget {
  const EvaluationSummaryCard({
    super.key,
    required this.evaluation,
    this.onTap,
  });

  final Evaluation evaluation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: uiSpacing12),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(uiSpacing16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                evaluation.evaluatorName,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _RecommendationBadge(recommendation: evaluation.recommendation),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: uiSpacing8),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: uiSpacing4),
                Text(
                  evaluation.overallScore.toStringAsFixed(1),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(evaluation.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (evaluation.comments.isNotEmpty) ...[
              const SizedBox(height: uiSpacing8),
              Text(
                evaluation.comments,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (evaluation.aiAssisted) ...[
              const SizedBox(height: uiSpacing8),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: uiSpacing4),
                  Text(
                    'AI Assisted',
                    style: textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (evaluation.aiOverridden)
                    Padding(
                      padding: const EdgeInsets.only(left: uiSpacing8),
                      child: Text(
                        '(Overridden)',
                        style: textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RecommendationBadge extends StatelessWidget {
  const _RecommendationBadge({required this.recommendation});

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context);
    return InfoPill(
      label: _getText(),
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.3),
      textColor: color,
    );
  }

  Color _getColor(BuildContext context) {
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

  String _getText() {
    switch (recommendation) {
      case Recommendation.strongYes:
        return 'STRONG YES';
      case Recommendation.yes:
        return 'YES';
      case Recommendation.neutral:
        return 'NEUTRAL';
      case Recommendation.no:
        return 'NO';
      case Recommendation.strongNo:
        return 'STRONG NO';
    }
  }
}
