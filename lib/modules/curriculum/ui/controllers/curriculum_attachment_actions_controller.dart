import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/curriculum/logic/curriculum_actions.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';

class CurriculumAttachmentActionsController {
  const CurriculumAttachmentActionsController._();

  static Future<void> pickAndUploadAttachment(BuildContext context) async {
    final result = await CurriculumLogic.pickAndUploadAttachment(
      context: context,
    );
    if (!context.mounted) return;
    _handleTextResult(
      context: context,
      result: result,
      successFallbackMessage: 'Archivo importado correctamente.',
    );
  }

  static Future<void> openAttachment({
    required BuildContext context,
    required CurriculumAttachment attachment,
  }) async {
    final result = await CurriculumLogic.openAttachment(
      context: context,
      attachment: attachment,
    );
    if (!context.mounted) return;
    if (result is ActionFailure<void>) {
      _showSnackBar(context, result.message);
    }
  }

  static Future<bool> confirmDeleteAttachment(BuildContext context) async {
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
    return shouldDelete ?? false;
  }

  static Future<void> deleteAttachment({
    required BuildContext context,
    required CurriculumAttachment attachment,
  }) async {
    final result = await CurriculumLogic.deleteAttachment(
      context: context,
      attachment: attachment,
    );
    if (!context.mounted) return;
    if (result is ActionFailure<void>) {
      _showSnackBar(context, result.message);
      return;
    }
    _showSnackBar(context, 'Archivo eliminado.');
  }

  static void _handleTextResult({
    required BuildContext context,
    required CurriculumActionResult<String> result,
    required String successFallbackMessage,
  }) {
    if (result is ActionFailure<String>) {
      _showSnackBar(context, result.message);
      return;
    }

    if (result is! ActionSuccess<String>) return;
    _showSnackBar(context, result.data ?? successFallbackMessage);
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
