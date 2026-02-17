import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/controllers/curriculum_item_dialog_controller.dart';

/// Shows a dialog to create or edit a curriculum item (experience or education).
///
/// Returns the created/edited [CurriculumItem] if the user confirms,
/// or `null` if they cancel.
Future<CurriculumItem?> showCurriculumItemDialog(
  BuildContext context, {
  CurriculumItem? initial,
}) {
  final controller = CurriculumItemDialogController(initial: initial);

  return showDialog<CurriculumItem>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(controller.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller.titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: controller.subtitleController,
                decoration: const InputDecoration(labelText: 'Subtítulo'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: controller.periodController,
                decoration: const InputDecoration(labelText: 'Periodo'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(controller.buildResult());
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}
