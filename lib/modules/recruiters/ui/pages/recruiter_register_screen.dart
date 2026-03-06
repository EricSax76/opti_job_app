import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/auth/ui/controllers/auth_screen_controller.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_state.dart';
import 'package:opti_job_app/modules/recruiters/ui/widgets/recruiter_register_form.dart';

class RecruiterRegisterScreen extends StatelessWidget {
  const RecruiterRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<RecruiterAuthCubit>().state;
    final viewModel = AuthFormScreenLogic.buildViewModel(authState.status);
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<RecruiterAuthCubit, RecruiterAuthState>(
      listenWhen: AuthFormScreenLogic.shouldListenRecruiterRegister,
      listener: AuthScreenController.handleRecruiterRegisterState,
      child: CoreShell(
        variant: CoreShellVariant.public,
        backgroundColor: background,
        body: RecruiterRegisterForm(
          isLoading: viewModel.isLoading,
          onSubmit: (name, email, password) =>
              AuthScreenController.submitRecruiterRegister(
                context,
                name: name,
                email: email,
                password: password,
              ),
          onLogin: () => context.go('/recruiter-login'),
        ),
      ),
    );
  }
}
