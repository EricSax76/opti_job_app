import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/profiles/cubits/profile_form_cubit.dart';
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
          onPickAvatar: formCubit.pickAvatar,
          onSubmit: () {
            if (_formKey.currentState?.validate() != true) return;
            formCubit.submit();
          },
        );
      },
    );
  }
}
