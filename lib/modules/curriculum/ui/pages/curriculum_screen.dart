import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/ui/controllers/curriculum_editor_actions_controller.dart';
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
      listener: (context, state) =>
          CurriculumEditorActionsController.handleNotice(
            context: context,
            state: state,
          ),
      builder: (context, state) {
        return CurriculumFormStateView(
          state: state,
          onRetry: formCubit.refresh,
          readyChild: CurriculumEditorFormLayout(
            state: state,
            onSubmit: formCubit.submit,
            onAddExperience: () =>
                CurriculumEditorActionsController.addExperience(context),
            onEditExperience: (index, item) =>
                CurriculumEditorActionsController.editExperience(
                  context,
                  index: index,
                  item: item,
                ),
            onRemoveExperience: formCubit.removeExperience,
            onAddEducation: () =>
                CurriculumEditorActionsController.addEducation(context),
            onEditEducation: (index, item) =>
                CurriculumEditorActionsController.editEducation(
                  context,
                  index: index,
                  item: item,
                ),
            onRemoveEducation: formCubit.removeEducation,
          ),
        );
      },
    );
  }
}
