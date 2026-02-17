import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_attachment_logic.dart';
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
    final viewModel = CurriculumAttachmentLogic.buildCardViewModel(attachment);

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
            child: const Icon(
              Icons.description_outlined,
              color: uiAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: uiSpacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.fileName,
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
                  viewModel.metadataLabel,
                  style: const TextStyle(color: uiMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onOpen != null)
            IconButton(
              tooltip: 'Abrir',
              onPressed: isBusy ? null : onOpen,
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: uiMuted,
              ),
            ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: isBusy ? null : onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: uiError,
            ),
          ),
        ],
      ),
    );
  }
}
