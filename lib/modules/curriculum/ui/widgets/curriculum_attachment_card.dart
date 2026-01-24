import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumAttachmentCard extends StatelessWidget {
  const CurriculumAttachmentCard({
    super.key,
    required this.attachment,
    required this.onDelete,
    this.onOpen,
    required this.isBusy,
  });

  final CurriculumAttachment attachment;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = _formatBytes(attachment.sizeBytes);
    final updatedLabel = attachment.updatedAt == null
        ? null
        : 'Actualizado: ${_formatDate(attachment.updatedAt!)}';

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing12),
      borderRadius: uiTileRadius,
      backgroundColor: uiWhite,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(uiSpacing12),
            decoration: BoxDecoration(
              color: uiAccentSoft,
              borderRadius: BorderRadius.circular(uiTileRadius),
            ),
            child: const Icon(Icons.description_outlined, color: uiAccent, size: 24),
          ),
          const SizedBox(width: uiSpacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: uiInk,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: uiSpacing4),
                Text(
                  [
                    sizeLabel,
                    if (updatedLabel != null) updatedLabel,
                  ].join(' · '),
                  style: const TextStyle(color: uiMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              tooltip: 'Abrir',
              onPressed: isBusy ? null : onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 20, color: uiMuted),
            ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: isBusy ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: uiError),
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
