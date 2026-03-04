import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';

class JobOfferMatchResultDialog extends StatelessWidget {
  const JobOfferMatchResultDialog({super.key, required this.result});

  final AiMatchResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text('Match: ${result.score}/100'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.summary != null) ...[
              Text(result.summary!),
              const SizedBox(height: uiSpacing12),
            ],
            if (result.reasons.isNotEmpty) ...[
              Text(
                'Puntos clave',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final reason in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8 - 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                ),
            ],
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: uiSpacing12 + 2),
              Text(
                'Recomendaciones',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: uiSpacing8),
              for (final recommendation in result.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: uiSpacing8 - 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                ),
            ],
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
