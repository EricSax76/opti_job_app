import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/auth/ui/controllers/auth_screen_controller.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_register_form.dart';

class CandidateRegisterScreen extends StatelessWidget {
  const CandidateRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CandidateAuthState authState = context
        .watch<CandidateAuthCubit>()
        .state;
    final viewModel = AuthFormScreenLogic.buildViewModel(authState.status);
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<CandidateAuthCubit, CandidateAuthState>(
      listenWhen: AuthFormScreenLogic.shouldListenCandidateRegister,
      listener: AuthScreenController.handleCandidateRegisterState,
      child: CoreShell(
        variant: CoreShellVariant.public,
        backgroundColor: background,
        body: CandidateRegisterForm(
          isLoading: viewModel.isLoading,
          onSubmit: (name, email, password) =>
              AuthScreenController.submitCandidateRegister(
                context,
                name: name,
                email: email,
                password: password,
              ),
          onLogin: () => context.go('/CandidateLogin'),
        ),
      ),
    );
  }
}
