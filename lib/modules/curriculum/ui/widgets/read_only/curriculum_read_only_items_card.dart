import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumReadOnlyItemsCard extends StatelessWidget {
  const CurriculumReadOnlyItemsCard({super.key, required this.items});

  final List<CurriculumItem> items;

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

  final CurriculumItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: uiInk,
          ),
        ),
        if (item.subtitle.isNotEmpty) ...[
          const SizedBox(height: uiSpacing4),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: uiMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
        if (item.period.isNotEmpty) ...[
          const SizedBox(height: uiSpacing4),
          Text(
            item.period,
            style: const TextStyle(color: uiMuted, fontSize: 13),
          ),
        ],
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: uiSpacing8),
          Text(
            item.description,
            style: const TextStyle(color: uiInk, height: 1.4, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
