import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_dialogs.dart';

class CurriculumEditorActionsController {
  const CurriculumEditorActionsController._();

  static void handleNotice({
    required BuildContext context,
    required CurriculumFormState state,
  }) {
    final message = state.noticeMessage;
    if (state.notice == null || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    context.read<CurriculumFormCubit>().clearNotice();
  }

  static Future<void> addExperience(BuildContext context) async {
    final created = await showCurriculumItemDialog(context);
    if (!context.mounted || created == null) return;
    context.read<CurriculumFormCubit>().addExperience(created);
  }

  static Future<void> editExperience(
    BuildContext context, {
    required int index,
    required CurriculumItem item,
  }) async {
    final updated = await showCurriculumItemDialog(context, initial: item);
    if (!context.mounted || updated == null) return;
    context.read<CurriculumFormCubit>().updateExperience(index, updated);
  }

  static Future<void> addEducation(BuildContext context) async {
    final created = await showCurriculumItemDialog(context);
    if (!context.mounted || created == null) return;
    context.read<CurriculumFormCubit>().addEducation(created);
  }

  static Future<void> editEducation(
    BuildContext context, {
    required int index,
    required CurriculumItem item,
  }) async {
    final updated = await showCurriculumItemDialog(context, initial: item);
    if (!context.mounted || updated == null) return;
    context.read<CurriculumFormCubit>().updateEducation(index, updated);
  }
}
