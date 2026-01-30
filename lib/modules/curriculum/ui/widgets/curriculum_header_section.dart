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
                : () async {
                     setState(() => _isManagingAttachment = true);
                     try {
                       final result = await CurriculumLogic.pickAndUploadAttachment(
                         context: context,
                       );
                       if (!context.mounted) return;
                       
                       if (result is ActionFailure) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text((result as ActionFailure).message)),
                         );
                       } else if (result is ActionSuccess<String>) {
                          final data = result.data;
                          if (data != null) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(data)),
                             );
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Archivo importado correctamente.')),
                             );
                          }
                       }
                     } finally {
                       if (mounted) setState(() => _isManagingAttachment = false);
                     }
                  },
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
            onOpen: () async {
               final result = await CurriculumLogic.openAttachment(
                  context: context,
                  attachment: attachment,
               );
               if (!context.mounted) return;
               if (result is ActionFailure) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(result.message)),
                 );
               }
            },
            onDelete: () async {
               final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Eliminar archivo'),
                      content: const Text(
                        'Se eliminará el archivo importado de tu curriculum.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    );
                  },
                );
                
                if (shouldDelete != true) return;
                if (!context.mounted) return;
                
                setState(() => _isManagingAttachment = true);
                try {
                  final result = await CurriculumLogic.deleteAttachment(
                    context: context, 
                    attachment: attachment
                  );
                  if (!context.mounted) return;

                  if (result is ActionFailure) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(result.message)),
                     );
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Archivo eliminado.')),
                     );
                  }
                } finally {
                  if (mounted) setState(() => _isManagingAttachment = false);
                }
            },
          ),
        ],
      ],
    );
  }
}
