import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_login_form.dart';

class CandidateLoginScreen extends StatefulWidget {
  const CandidateLoginScreen({super.key});

  @override
  State<CandidateLoginScreen> createState() => _CandidateLoginScreenState();
}

class _CandidateLoginScreenState extends State<CandidateLoginScreen> {
  @override
  Widget build(BuildContext context) {
    final CandidateAuthState authState = context
        .watch<CandidateAuthCubit>()
        .state;
    final isLoading = authState.status == AuthStatus.authenticating;
    const background = uiBackground;

    return BlocListener<CandidateAuthCubit, CandidateAuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        } else if (state.isAuthenticated &&
            state.status == AuthStatus.authenticated &&
            !state.needsOnboarding) {
          final uid = state.candidate?.uid;
          if (uid != null && uid.isNotEmpty) {
            context.go('/candidate/$uid/dashboard');
          } else {
            context.go('/CandidateDashboard');
          }
        }
      },
      child: Scaffold(
        appBar: const AppNavBar(),
        backgroundColor: background,
        body: CandidateLoginForm(
          isLoading: isLoading,
          onSubmit: _submit,
          onRegister: () => context.go('/candidateregister'),
        ),
      ),
    );
  }

  void _submit(String email, String password) {
    context.read<CandidateAuthCubit>().loginCandidate(
      email: email,
      password: password,
    );
  }
}
