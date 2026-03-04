import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class SourceEffectivenessChart extends StatelessWidget {
  const SourceEffectivenessChart({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sourceLabelStyle = textTheme.bodySmall;
    final ratioStyle = textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final detailStyle = textTheme.labelSmall;
    final sources = data.entries.toList()
      ..sort((a, b) {
        final aMetrics = Map<String, dynamic>.from(a.value as Map);
        final bMetrics = Map<String, dynamic>.from(b.value as Map);
        final aHires = (aMetrics['hires'] as num?)?.toInt() ?? 0;
        final bHires = (bMetrics['hires'] as num?)?.toInt() ?? 0;
        return bHires.compareTo(aHires);
      });

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Efectividad por Fuente',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: uiSpacing16),
          if (sources.isEmpty)
            Text(
              'Sin datos de fuentes para este periodo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ...sources.map((entry) {
            final metrics = Map<String, dynamic>.from(entry.value as Map);
            final hires = (metrics['hires'] as num?)?.toInt() ?? 0;
            final apps = (metrics['applications'] as num?)?.toInt() ?? 0;
            final spend = (metrics['spendEur'] as num?)?.toDouble() ?? 0;
            final roi = (metrics['roi'] as num?)?.toDouble() ?? 0;
            final costPerHire =
                (metrics['costPerHireEur'] as num?)?.toDouble() ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: uiSpacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(entry.key, style: sourceLabelStyle)),
                      Text('$hires/$apps', style: ratioStyle),
                    ],
                  ),
                  const SizedBox(height: uiSpacing4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: apps > 0 ? hires / apps : 0,
                      minHeight: uiSpacing8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: uiSpacing4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Inversión: €${spend.toStringAsFixed(2)}',
                          style: detailStyle,
                        ),
                      ),
                      Text(
                        'CPH €${costPerHire.toStringAsFixed(2)}',
                        style: detailStyle,
                      ),
                      const SizedBox(width: uiSpacing8),
                      Text(
                        'ROI ${(roi * 100).toStringAsFixed(1)}%',
                        style: detailStyle,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
