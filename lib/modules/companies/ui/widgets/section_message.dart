import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

class SectionMessage extends StatelessWidget {
  const SectionMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? colorScheme.surface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(uiCardRadius),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Text(
        text,
        style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
      ),
    );
  }
}
