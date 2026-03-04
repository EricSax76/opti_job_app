import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/analytics/models/performance_dashboard.dart';

class InpPerformanceCard extends StatelessWidget {
  const InpPerformanceCard({super.key, required this.dashboard});

  final PerformanceDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDegraded = dashboard.inpDegraded;
    final tone = isDegraded ? colorScheme.error : colorScheme.tertiary;
    final statusLabel = isDegraded ? 'Degradado' : 'En objetivo';

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      borderRadius: uiTileRadius,
      borderColor: colorScheme.outlineVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDegraded ? Icons.warning_amber_rounded : Icons.speed_rounded,
                color: tone,
              ),
              const SizedBox(width: uiSpacing8),
              Text(
                'INP p75 (Web)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: tone),
                ),
              ),
            ],
          ),
          const SizedBox(height: uiSpacing12),
          Text(
            '${dashboard.inpP75Ms.toStringAsFixed(0)} ms',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: uiSpacing4),
          Text(
            'Objetivo: < ${dashboard.thresholdMs} ms • Muestras: ${dashboard.inpSamples}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (isDegraded) ...[
            const SizedBox(height: uiSpacing8),
            Text(
              'Alerta: el p75 supera el umbral y puede afectar conversión del flujo de candidatura.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
