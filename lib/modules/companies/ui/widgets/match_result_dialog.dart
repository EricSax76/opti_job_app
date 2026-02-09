import 'package:flutter/material.dart';
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
            if (result.summary != null) ...[
              Text(result.summary!),
              const SizedBox(height: 12),
            ],
            if (result.reasons.isNotEmpty) ...[
              Text(
                'Motivos',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final reason in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BulletText(
                    icon: Icons.check_circle_outline,
                    text: reason,
                  ),
                ),
              const SizedBox(height: 8),
            ],
            if (result.recommendations.isNotEmpty) ...[
              Text(
                'Recomendaciones',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              for (final recommendation in result.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BulletText(
                    icon: Icons.tips_and_updates_outlined,
                    text: recommendation,
                  ),
                ),
            ],
            if (result.summary == null &&
                result.reasons.isEmpty &&
                result.recommendations.isEmpty)
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
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
