import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_attachment_card.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_actions.dart';

class CurriculumHeaderSection extends StatefulWidget {
  const CurriculumHeaderSection({super.key, required this.isSaving});

  final bool isSaving;

  @override
  State<CurriculumHeaderSection> createState() =>
      _CurriculumHeaderSectionState();
}

class _CurriculumHeaderSectionState extends State<CurriculumHeaderSection> {
  var _isManagingAttachment = false;

  @override
  Widget build(BuildContext context) {
    final isAnalyzing = context.select(
      (CurriculumFormCubit cubit) => cubit.state.isAnalyzing,
    );
    final attachment =
        context.watch<CurriculumCubit>().state.curriculum?.attachment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Curriculum',
          subtitle: 'Completa tu CV para postular más rápido.',
          action: OutlinedButton.icon(
            onPressed: widget.isSaving || _isManagingAttachment || isAnalyzing
                ? null
                : () => CurriculumLogic.pickAndUploadAttachment(
                      context: context,
                      onStart: () =>
                          setState(() => _isManagingAttachment = true),
                      onEnd: () => setState(() => _isManagingAttachment = false),
                    ),
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
            ),
          ),
        ),
        if (attachment != null) ...[
          const SizedBox(height: uiSpacing16),
          CurriculumAttachmentCard(
            attachment: attachment,
            isBusy: widget.isSaving || _isManagingAttachment,
            onOpen: () => CurriculumLogic.openAttachment(
              context: context,
              attachment: attachment,
            ),
            onDelete: () => CurriculumLogic.confirmAndDeleteAttachment(
              context: context,
              attachment: attachment,
              onStart: () => setState(() => _isManagingAttachment = true),
              onEnd: () => setState(() => _isManagingAttachment = false),
            ),
          ),
        ],
      ],
    );
  }
}
