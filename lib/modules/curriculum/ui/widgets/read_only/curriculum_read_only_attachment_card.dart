import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class CurriculumReadOnlyAttachmentCard extends StatelessWidget {
  const CurriculumReadOnlyAttachmentCard({super.key, required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: uiSpacing16, vertical: uiSpacing12),
      backgroundColor: isDark 
          ? colorScheme.onSurface.withValues(alpha: 0.05) 
          : colorScheme.primary.withValues(alpha: 0.05),
      borderColor: Colors.transparent,
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: colorScheme.primary, size: 20),
          const SizedBox(width: uiSpacing12),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
