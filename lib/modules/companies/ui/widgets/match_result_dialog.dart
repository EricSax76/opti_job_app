import 'package:flutter/material.dart';
import 'package:opti_job_app/features/ai/models/ai_match_result.dart';

class MatchResultDialog extends StatelessWidget {
  const MatchResultDialog({super.key, required this.result});
  final AiMatchResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Match (Empresa): ${result.score}/100'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.summary != null) Text(result.summary!),
            // ... renderizado de reasons y recommendations
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
