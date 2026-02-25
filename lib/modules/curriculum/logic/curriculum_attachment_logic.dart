import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/models/curriculum_attachment_card_view_model.dart';

class CurriculumAttachmentLogic {
  const CurriculumAttachmentLogic._();

  static CurriculumAttachmentCardViewModel buildCardViewModel(
    CurriculumAttachment attachment,
  ) {
    final sizeLabel = _formatBytes(attachment.sizeBytes);
    final updatedLabel = attachment.updatedAt == null
        ? null
        : 'Actualizado: ${_formatDate(attachment.updatedAt!)}';

    return CurriculumAttachmentCardViewModel(
      fileName: attachment.fileName,
      metadataLabel: [sizeLabel, ?updatedLabel].join(' · '),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];

    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final fixed = unitIndex == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$fixed ${units[unitIndex]}';
  }

  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}
