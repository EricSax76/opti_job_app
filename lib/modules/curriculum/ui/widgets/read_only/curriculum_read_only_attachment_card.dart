import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';

class CurriculumReadOnlyAttachmentCard extends StatelessWidget {
  const CurriculumReadOnlyAttachmentCard({super.key, required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      backgroundColor: uiAccentSoft,
      borderColor: Colors.transparent,
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: uiAccent, size: 24),
          const SizedBox(width: uiSpacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    color: uiInk,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: uiSpacing4),
                Text(
                  'Archivo importado',
                  style: TextStyle(
                    color: uiMuted.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
