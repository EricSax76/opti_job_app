import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/auth/ui/controllers/auth_screen_controller.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/core/widgets/auth_login_form.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_state.dart';

class RecruiterLoginScreen extends StatelessWidget {
  const RecruiterLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RecruiterAuthState authState = context
        .watch<RecruiterAuthCubit>()
        .state;
    final viewModel = AuthFormScreenLogic.buildViewModel(authState.status);
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<RecruiterAuthCubit, RecruiterAuthState>(
      listenWhen: AuthFormScreenLogic.shouldListenRecruiterLogin,
      listener: AuthScreenController.handleRecruiterLoginState,
      child: CoreShell(
        variant: CoreShellVariant.public,
        backgroundColor: background,
        body: AuthLoginForm(
          tagline: 'RECLUTADORES',
          title: 'Acceso al equipo',
          subtitle:
              'Inicia sesión con tu usuario de reclutador para gestionar candidatos.',
          emailIcon: Icons.groups_outlined,
          isLoading: viewModel.isLoading,
          onSubmit: (email, password) =>
              AuthScreenController.submitRecruiterLogin(
                context,
                email: email,
                password: password,
              ),
          onRegister: () => context.go('/recruiter-register'),
        ),
      ),
    );
  }
}
