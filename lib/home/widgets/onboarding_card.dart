import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';

class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.greeting,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String greeting;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          margin: const EdgeInsets.all(uiSpacing24),
          child: Padding(
            padding: const EdgeInsets.all(uiSpacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: uiSpacing12),
                Text(message, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: uiSpacing24),
                FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(confirmLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
