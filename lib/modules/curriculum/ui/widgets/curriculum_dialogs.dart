import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

/// Shows a dialog to create or edit a curriculum item (experience or education).
///
/// Returns the created/edited [CurriculumItem] if the user confirms,
/// or `null` if they cancel.
Future<CurriculumItem?> showCurriculumItemDialog(
  BuildContext context, {
  CurriculumItem? initial,
}) {
  final initialItem = initial ?? CurriculumItem.empty();
  final titleController = TextEditingController(text: initialItem.title);
  final subtitleController = TextEditingController(text: initialItem.subtitle);
  final periodController = TextEditingController(text: initialItem.period);
  final descriptionController = TextEditingController(
    text: initialItem.description,
  );

  return showDialog<CurriculumItem>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(initial == null ? 'Agregar' : 'Editar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Subtítulo'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: periodController,
                decoration: const InputDecoration(labelText: 'Periodo'),
              ),
              const SizedBox(height: uiSpacing12),
              TextFormField(
                controller: descriptionController,
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
              Navigator.of(context).pop(
                CurriculumItem(
                  title: titleController.text.trim(),
                  subtitle: subtitleController.text.trim(),
                  period: periodController.text.trim(),
                  description: descriptionController.text.trim(),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  ).whenComplete(() {
    titleController.dispose();
    subtitleController.dispose();
    periodController.dispose();
    descriptionController.dispose();
  });
}
