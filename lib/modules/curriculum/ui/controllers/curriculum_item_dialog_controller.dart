import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumItemDialogController {
  CurriculumItemDialogController({CurriculumItem? initial})
    : _isEditing = initial != null,
      titleController = TextEditingController(text: initial?.title ?? ''),
      subtitleController = TextEditingController(text: initial?.subtitle ?? ''),
      periodController = TextEditingController(text: initial?.period ?? ''),
      descriptionController = TextEditingController(
        text: initial?.description ?? '',
      );

  final bool _isEditing;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController periodController;
  final TextEditingController descriptionController;

  String get title => _isEditing ? 'Editar' : 'Agregar';

  CurriculumItem buildResult() {
    return CurriculumItem(
      title: titleController.text.trim(),
      subtitle: subtitleController.text.trim(),
      period: periodController.text.trim(),
      description: descriptionController.text.trim(),
    );
  }

  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    periodController.dispose();
    descriptionController.dispose();
  }
}
