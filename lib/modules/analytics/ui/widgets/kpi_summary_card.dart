import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/analytics/models/kpi_metric.dart';

class KpiSummaryCard extends StatelessWidget {
  const KpiSummaryCard({super.key, required this.metric});

  final KpiMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isNegative = (metric.change ?? 0) < 0;
    final isGood = metric.isPositiveGood ? !isNegative : isNegative;
    final color = isGood ? scheme.tertiary : scheme.error;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: theme.textTheme.bodySmall),
          const SizedBox(height: uiSpacing8),
          Row(
            children: [
              Text(
                '${metric.value}${metric.unit}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (metric.change != null)
                InfoPill(
                  icon: isNegative ? Icons.trending_down : Icons.trending_up,
                  label: '${metric.change!.toStringAsFixed(1)}%',
                  backgroundColor: color.withValues(alpha: 0.1),
                  borderColor: color.withValues(alpha: 0.2),
                  textColor: color,
                  iconColor: color,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
