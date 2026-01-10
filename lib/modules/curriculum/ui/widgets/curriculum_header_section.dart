import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubit/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_attachment_card.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_logic.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_styles.dart';

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
    final attachment = context
        .watch<CurriculumCubit>()
        .state
        .curriculum
        ?.attachment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Curriculum',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.isSaving || _isManagingAttachment || isAnalyzing
                  ? null
                  : () => CurriculumLogic.pickAndUploadAttachment(
                      context: context,
                      onStart: () => setState(() => _isManagingAttachment = true),
                      onEnd: () => setState(() => _isManagingAttachment = false),
                    ),
              icon: _isManagingAttachment || isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(
                isAnalyzing
                    ? 'Analizando...'
                    : _isManagingAttachment
                    ? 'Subiendo...'
                    : 'Importar PDF/DOCX',
              ),
            ),
          ],
        ),
        if (attachment != null) ...[
          const SizedBox(height: 16),
          CurriculumAttachmentCard(
            attachment: attachment,
            isBusy: widget.isSaving || _isManagingAttachment,
            onDelete: () => CurriculumLogic.confirmAndDeleteAttachment(
              context: context,
              attachment: attachment,
              onStart: () => setState(() => _isManagingAttachment = true),
              onEnd: () => setState(() => _isManagingAttachment = false),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Completa tu CV para postular más rápido.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: cvMuted),
        ),
      ],
    );
  }
}
