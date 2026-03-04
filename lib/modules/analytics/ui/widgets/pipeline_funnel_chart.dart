import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class PipelineFunnelChart extends StatelessWidget {
  const PipelineFunnelChart({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stageLabelStyle = textTheme.bodySmall;
    final stageValueStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final progressLabelStyle = textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: scheme.onPrimary,
    );
    // Expected data format: { stageId: { name: '...', entered: 100, advanced: 80, rate: 0.8 } }
    final stages = data.entries.toList();

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Embudo de Conversión (Pipeline)',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: uiSpacing16),
          ...stages.map((entry) {
            final stageData = entry.value as Map<String, dynamic>;
            final rate = (stageData['rate'] as num?)?.toDouble() ?? 0.0;
            final entered = (stageData['entered'] as num?)?.toInt() ?? 0;
            final name = stageData['name'] ?? entry.key;

            return Padding(
              padding: const EdgeInsets.only(bottom: uiSpacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: stageLabelStyle),
                      Text('$entered cand.', style: stageValueStyle),
                    ],
                  ),
                  const SizedBox(height: uiSpacing4),
                  Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(uiSpacing4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: rate.clamp(0.0, 1.0),
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                scheme.primary,
                                scheme.primary.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(uiSpacing4),
                          ),
                          child: Center(
                            child: Text(
                              '${(rate * 100).toStringAsFixed(1)}%',
                              style: progressLabelStyle,
                            ),
                          ),
                        ),
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
