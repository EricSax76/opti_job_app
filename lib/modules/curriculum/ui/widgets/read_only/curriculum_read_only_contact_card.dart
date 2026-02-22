import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/ui/models/curriculum_read_only_view_model.dart';

class CurriculumReadOnlyContactCard extends StatelessWidget {
  const CurriculumReadOnlyContactCard({super.key, required this.viewModel});

  final CurriculumReadOnlyContactViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.hasPhone)
            _ContactRow(icon: Icons.phone_outlined, label: viewModel.phone!),
          if (viewModel.showDivider)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: uiSpacing12),
              child: Divider(height: 1),
            ),
          if (viewModel.hasLocation)
            _ContactRow(icon: Icons.place_outlined, label: viewModel.location!),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: uiSpacing12),
        Text(label, style: TextStyle(color: colorScheme.onSurface, fontSize: 15)),
      ],
    );
  }
}
