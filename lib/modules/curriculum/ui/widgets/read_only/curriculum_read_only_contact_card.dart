import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class CurriculumReadOnlyContactCard extends StatelessWidget {
  const CurriculumReadOnlyContactCard({super.key, this.phone, this.location});

  final String? phone;
  final String? location;

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    final hasLocation = location != null && location!.trim().isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhone)
            _ContactRow(icon: Icons.phone_outlined, label: phone!.trim()),
          if (hasPhone && hasLocation)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: uiSpacing12),
              child: Divider(height: 1),
            ),
          if (hasLocation)
            _ContactRow(icon: Icons.place_outlined, label: location!.trim()),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: uiMuted),
        const SizedBox(width: uiSpacing12),
        Text(label, style: const TextStyle(color: uiInk, fontSize: 15)),
      ],
    );
  }
}
