import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubit/auth_status.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_login_form.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CompanyAuthCubit>().state;
    final isLoading = authState.status == AuthStatus.authenticating;
    const background = uiBackground;

    return BlocListener<CompanyAuthCubit, CompanyAuthState>(
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
          context.go('/DashboardCompany');
        }
      },
      child: Scaffold(
        appBar: const AppNavBar(),
        backgroundColor: background,
        body: CompanyLoginForm(
          isLoading: isLoading,
          onSubmit: _submit,
          onRegister: () => context.go('/companyregister'),
        ),
      ),
    );
  }

  void _submit(String email, String password) {
    context.read<CompanyAuthCubit>().loginCompany(
      email: email,
      password: password,
    );
  }
}
