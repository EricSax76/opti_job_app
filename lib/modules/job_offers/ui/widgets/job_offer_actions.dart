import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applications/ui/application_status.dart';

class JobOfferActions extends StatelessWidget {
  const JobOfferActions({
    super.key,
    required this.isAuthenticated,
    required this.isApplying,
    required this.applicationStatus,
    required this.onApply,
    required this.onMatch,
    required this.onBack,
  });

  final bool isAuthenticated;
  final bool isApplying;
  final String? applicationStatus;
  final VoidCallback onApply;
  final VoidCallback? onMatch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final hasApplied = applicationStatus != null;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (isAuthenticated)
          FilledButton(
            onPressed: (isApplying || hasApplied) ? null : onApply,
            style: FilledButton.styleFrom(backgroundColor: uiInk),
            child: isApplying
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    hasApplied
                        ? 'Postulación: ${applicationStatusLabel(applicationStatus!)}'
                        : 'Postularme',
                  ),
          ),
        if (isAuthenticated)
          OutlinedButton.icon(
            onPressed: isApplying ? null : onMatch,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Match'),
          ),
        OutlinedButton(
          onPressed: isApplying ? null : onBack,
          child: const Text('Volver'),
        ),
      ],
    );
  }
}
