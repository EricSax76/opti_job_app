import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/profiles/cubits/profile_form_cubit.dart';
import 'package:opti_job_app/modules/profiles/ui/controllers/profile_form_controller.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_form_content.dart';

class ProfileFormContainer extends StatefulWidget {
  const ProfileFormContainer({super.key});

  @override
  State<ProfileFormContainer> createState() => _ProfileFormContainerState();
}

class _ProfileFormContainerState extends State<ProfileFormContainer> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<ProfileFormCubit>();

    return BlocBuilder<ProfileFormCubit, ProfileFormState>(
      builder: (context, state) {
        return ProfileFormContent(
          formKey: _formKey,
          state: state,
          nameController: formCubit.nameController,
          lastNameController: formCubit.lastNameController,
          emailController: formCubit.emailController,
          targetRoleController: formCubit.targetRoleController,
          preferredLocationController: formCubit.preferredLocationController,
          onboardingDraft: state.onboardingDraft,
          onPickAvatar: formCubit.pickAvatar,
          onPreferredModalityChanged: formCubit.updatePreferredModality,
          onPreferredSeniorityChanged: formCubit.updatePreferredSeniority,
          onWorkStyleSkippedChanged: formCubit.updateWorkStyleSkipped,
          onStartOfDayChanged: formCubit.updateStartOfDayPreference,
          onFeedbackChanged: formCubit.updateFeedbackPreference,
          onStructureChanged: formCubit.updateStructurePreference,
          onTaskPaceChanged: formCubit.updateTaskPacePreference,
          onSubmit: () => ProfileFormController.submit(
            formKey: _formKey,
            formCubit: formCubit,
            state: state,
          ),
        );
      },
    );
  }
}
