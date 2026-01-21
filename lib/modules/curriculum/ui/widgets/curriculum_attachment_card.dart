import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumAttachmentCard extends StatelessWidget {
  const CurriculumAttachmentCard({
    super.key,
    required this.attachment,
    required this.onDelete,
    required this.isBusy,
  });

  final CurriculumAttachment attachment;
  final VoidCallback onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = _formatBytes(attachment.sizeBytes);
    final updatedLabel = attachment.updatedAt == null
        ? null
        : 'Actualizado: ${_formatDate(attachment.updatedAt!)}';

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing12 + 2),
      borderRadius: uiTileRadius,
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: uiMuted),
          const SizedBox(width: uiSpacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: uiInk,
                      ),
                ),
                const SizedBox(height: uiSpacing4),
                Text(
                  [
                    sizeLabel,
                    if (updatedLabel != null) updatedLabel,
                  ].join(' · '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: uiMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: isBusy ? null : onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final fixed =
        unitIndex == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$fixed ${units[unitIndex]}';
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

