import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/logic/curriculum_actions.dart';

class CurriculumSummaryActionsController {
  const CurriculumSummaryActionsController._();

  static Future<void> improveSummary({
    required BuildContext context,
    required CurriculumFormState state,
  }) async {
    final result = await CurriculumLogic.improveSummary(
      context: context,
      state: state,
    );
    if (!context.mounted) return;

    if (result is ActionFailure<String>) {
      _showSnackBar(context, result.message);
      return;
    }

    if (result is! ActionSuccess<String>) return;
    final suggestion = result.data;
    if (suggestion == null || suggestion.trim().isEmpty) return;

    final shouldApply = await _showApplySuggestionDialog(
      context: context,
      suggestion: suggestion,
    );
    if (shouldApply != true || !context.mounted) return;

    context.read<CurriculumFormCubit>().summaryController.text = suggestion;
  }

  static Future<bool?> _showApplySuggestionDialog({
    required BuildContext context,
    required String suggestion,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Resumen sugerido'),
          content: SingleChildScrollView(child: SelectableText(suggestion)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
