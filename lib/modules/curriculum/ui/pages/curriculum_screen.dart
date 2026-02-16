import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_dialogs.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/editor/curriculum_editor_form_layout.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/editor/curriculum_form_state_view.dart';

class CurriculumScreen extends StatelessWidget {
  const CurriculumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CurriculumFormCubit(curriculumCubit: context.read<CurriculumCubit>()),
      child: const _CurriculumScreenContainer(),
    );
  }
}

class _CurriculumScreenContainer extends StatelessWidget {
  const _CurriculumScreenContainer();

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<CurriculumFormCubit>();

    return BlocConsumer<CurriculumFormCubit, CurriculumFormState>(
      listener: _handleNotice,
      builder: (context, state) {
        return CurriculumFormStateView(
          state: state,
          onRetry: formCubit.refresh,
          readyChild: CurriculumEditorFormLayout(
            state: state,
            onSubmit: formCubit.submit,
            onAddExperience: () => _addExperience(context),
            onEditExperience: (index, item) =>
                _editExperience(context, index: index, item: item),
            onRemoveExperience: formCubit.removeExperience,
            onAddEducation: () => _addEducation(context),
            onEditEducation: (index, item) =>
                _editEducation(context, index: index, item: item),
            onRemoveEducation: formCubit.removeEducation,
          ),
        );
      },
    );
  }

  void _handleNotice(BuildContext context, CurriculumFormState state) {
    if (state.notice == null || state.noticeMessage == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
    context.read<CurriculumFormCubit>().clearNotice();
  }

  Future<void> _addExperience(BuildContext context) async {
    final created = await showCurriculumItemDialog(context);
    if (!context.mounted || created == null) return;

    context.read<CurriculumFormCubit>().addExperience(created);
  }

  Future<void> _editExperience(
    BuildContext context, {
    required int index,
    required CurriculumItem item,
  }) async {
    final updated = await showCurriculumItemDialog(context, initial: item);
    if (!context.mounted || updated == null) return;

    context.read<CurriculumFormCubit>().updateExperience(index, updated);
  }

  Future<void> _addEducation(BuildContext context) async {
    final created = await showCurriculumItemDialog(context);
    if (!context.mounted || created == null) return;

    context.read<CurriculumFormCubit>().addEducation(created);
  }

  Future<void> _editEducation(
    BuildContext context, {
    required int index,
    required CurriculumItem item,
  }) async {
    final updated = await showCurriculumItemDialog(context, initial: item);
    if (!context.mounted || updated == null) return;

    context.read<CurriculumFormCubit>().updateEducation(index, updated);
  }
}
