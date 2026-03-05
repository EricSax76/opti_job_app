import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/applications/models/application_status.dart';

class JobOfferActions extends StatelessWidget {
  const JobOfferActions({
    super.key,
    required this.isAuthenticated,
    required this.canApply,
    required this.isApplying,
    required this.applicationStatus,
    required this.onApply,
    this.onQualifiedSign,
    required this.onMatch,
    required this.onBack,
  });

  final bool isAuthenticated;
  final bool canApply;
  final bool isApplying;
  final String? applicationStatus;
  final VoidCallback onApply;
  final VoidCallback? onQualifiedSign;
  final VoidCallback? onMatch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasApplied = applicationStatus != null;
    final normalizedStatus = applicationStatus?.trim().toLowerCase() ?? '';
    final canSignOffer =
        normalizedStatus == 'offered' ||
        normalizedStatus == 'accepted_pending_signature';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (isAuthenticated)
          FilledButton(
            onPressed: (isApplying || hasApplied || !canApply) ? null : onApply,
            style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
            child: isApplying
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    hasApplied
                        ? 'Postulación: ${ApplicationStatus.fromString(applicationStatus).label}'
                        : !canApply
                        ? 'Oferta no activa'
                        : 'Postularme',
                  ),
          ),
        if (isAuthenticated && canSignOffer && onQualifiedSign != null)
          FilledButton.icon(
            onPressed: isApplying ? null : onQualifiedSign,
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Firmar oferta'),
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
