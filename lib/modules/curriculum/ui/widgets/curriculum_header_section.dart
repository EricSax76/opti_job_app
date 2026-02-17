import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/controllers/curriculum_attachment_actions_controller.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_attachment_card.dart';

class CurriculumHeaderSection extends StatefulWidget {
  const CurriculumHeaderSection({super.key, required this.isSaving});

  final bool isSaving;

  @override
  State<CurriculumHeaderSection> createState() =>
      _CurriculumHeaderSectionState();
}

class _CurriculumHeaderSectionState extends State<CurriculumHeaderSection> {
  var _isManagingAttachment = false;

  Future<void> _handlePickAttachment() async {
    setState(() => _isManagingAttachment = true);
    try {
      await CurriculumAttachmentActionsController.pickAndUploadAttachment(
        context,
      );
    } finally {
      if (mounted) setState(() => _isManagingAttachment = false);
    }
  }

  Future<void> _handleOpenAttachment(CurriculumAttachment attachment) {
    return CurriculumAttachmentActionsController.openAttachment(
      context: context,
      attachment: attachment,
    );
  }

  Future<void> _handleDeleteAttachment(CurriculumAttachment attachment) async {
    final shouldDelete =
        await CurriculumAttachmentActionsController.confirmDeleteAttachment(
          context,
        );
    if (!shouldDelete || !mounted) return;

    setState(() => _isManagingAttachment = true);
    try {
      await CurriculumAttachmentActionsController.deleteAttachment(
        context: context,
        attachment: attachment,
      );
    } finally {
      if (mounted) setState(() => _isManagingAttachment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnalyzing = context.select(
      (CurriculumFormCubit cubit) => cubit.state.isAnalyzing,
    );
    final attachment = context
        .watch<CurriculumCubit>()
        .state
        .curriculum
        ?.attachment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Curriculum',
          subtitle: 'Completa tu CV para postular más rápido.',
          titleFontSize: 22,
          action: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: uiSpacing12,
                vertical: uiSpacing8,
              ),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: widget.isSaving || _isManagingAttachment || isAnalyzing
                ? null
                : _handlePickAttachment,
            icon: _isManagingAttachment || isAnalyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(
              isAnalyzing
                  ? 'Analizando...'
                  : _isManagingAttachment
                  ? 'Subiendo...'
                  : 'Importar PDF',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (attachment != null) ...[
          const SizedBox(height: uiSpacing16),
          CurriculumAttachmentCard(
            attachment: attachment,
            isBusy: widget.isSaving || _isManagingAttachment,
            onOpen: () => _handleOpenAttachment(attachment),
            onDelete: () => _handleDeleteAttachment(attachment),
          ),
        ],
      ],
    );
  }
}
