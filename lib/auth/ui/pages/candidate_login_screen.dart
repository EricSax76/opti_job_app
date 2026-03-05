import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/auth/ui/controllers/auth_screen_controller.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_login_form.dart';

class CandidateLoginScreen extends StatelessWidget {
  const CandidateLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CandidateAuthState authState = context
        .watch<CandidateAuthCubit>()
        .state;
    final viewModel = AuthFormScreenLogic.buildViewModel(authState.status);
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<CandidateAuthCubit, CandidateAuthState>(
      listenWhen: AuthFormScreenLogic.shouldListenCandidateLogin,
      listener: AuthScreenController.handleCandidateLoginState,
      child: CoreShell(
        variant: CoreShellVariant.public,
        backgroundColor: background,
        body: CandidateLoginForm(
          isLoading: viewModel.isLoading,
          onSubmit: (email, password) =>
              AuthScreenController.submitCandidateLogin(
                context,
                email: email,
                password: password,
              ),
          onRegister: () => context.go('/candidateregister'),
          onGoogleSignIn: () =>
              AuthScreenController.submitCandidateGoogleSignIn(context),
          onEudiWallet: () =>
              AuthScreenController.submitCandidateWalletSignIn(context),
        ),
      ),
    );
  }
}
