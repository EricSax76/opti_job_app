import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_register_form.dart';

class CandidateRegisterScreen extends StatefulWidget {
  const CandidateRegisterScreen({super.key});

  @override
  State<CandidateRegisterScreen> createState() =>
      _CandidateRegisterScreenState();
}

class _CandidateRegisterScreenState extends State<CandidateRegisterScreen> {
  @override
  Widget build(BuildContext context) {
    final CandidateAuthState authState = context
        .watch<CandidateAuthCubit>()
        .state;
    final isLoading = authState.status == AuthStatus.authenticating;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<CandidateAuthCubit, CandidateAuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.needsOnboarding != current.needsOnboarding,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        } else if (state.isAuthenticated && state.needsOnboarding) {
          context.go('/onboarding');
        }
      },
      child: Scaffold(
        appBar: const AppNavBar(),
        backgroundColor: background,
        body: CandidateRegisterForm(
          isLoading: isLoading,
          onSubmit: _submit,
          onLogin: () => context.go('/CandidateLogin'),
        ),
      ),
    );
  }

  void _submit(String name, String email, String password) {
    context.read<CandidateAuthCubit>().registerCandidate(
      name: name,
      email: email,
      password: password,
    );
  }
}
