import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class TimeToHireChart extends StatelessWidget {
  const TimeToHireChart({super.key, required this.avgTimeToHire});

  final double avgTimeToHire;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        children: [
          Icon(Icons.speed, size: 48, color: primary),
          const SizedBox(height: uiSpacing8),
          Text(
            'Promedio Tiempo de Contratación',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: uiSpacing8),
          Text(
            '${avgTimeToHire.toStringAsFixed(1)} días',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: uiSpacing8),
          Text(
            'Meta: < 25 días',
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
