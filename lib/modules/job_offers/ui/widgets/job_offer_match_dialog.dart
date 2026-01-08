import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/ai/models/ai_match_result.dart';

class JobOfferMatchResultDialog extends StatelessWidget {
  const JobOfferMatchResultDialog({super.key, required this.result});

  final AiMatchResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Match: ${result.score}/100'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.summary != null) ...[
              Text(result.summary!),
              const SizedBox(height: 12),
            ],
            if (result.reasons.isNotEmpty) ...[
              const Text(
                'Puntos clave',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final reason in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
              const SizedBox(height: 14),
              const Text(
                'Recomendaciones',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final recommendation in result.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
