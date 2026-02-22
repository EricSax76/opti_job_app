import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/ui/models/curriculum_read_only_view_model.dart';

class CurriculumReadOnlyItemsCard extends StatelessWidget {
  const CurriculumReadOnlyItemsCard({super.key, required this.items});

  final List<CurriculumReadOnlyItemViewModel> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _CurriculumItemBlock(item: items[i]),
            if (i < items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: uiSpacing16),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _CurriculumItemBlock extends StatelessWidget {
  const _CurriculumItemBlock({required this.item});

  final CurriculumReadOnlyItemViewModel item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        if (item.hasSubtitle) ...[
          const SizedBox(height: uiSpacing4),
          Text(
            item.subtitle!,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
        if (item.hasPeriod) ...[
          const SizedBox(height: uiSpacing4),
          Text(
            item.period!,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
        if (item.hasDescription) ...[
          const SizedBox(height: uiSpacing8),
          Text(
            item.description!,
            style: TextStyle(
                color: colorScheme.onSurface, height: 1.4, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
