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
    // Expected format: { sourceName: { applications: 100, hires: 10 } }
    final sources = data.entries.toList();

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
          ...sources.map((entry) {
            final metrics = entry.value as Map<String, dynamic>;
            final hires = (metrics['hires'] as num?)?.toInt() ?? 0;
            final apps = (metrics['applications'] as num?)?.toInt() ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: uiSpacing8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key, style: sourceLabelStyle),
                  ),
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: apps > 0 ? hires / apps : 0,
                        minHeight: uiSpacing8,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: uiSpacing8),
                  Text('$hires/$apps', style: ratioStyle),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
