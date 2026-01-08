import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubit/auth_status.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/core/widgets/app_nav_bar.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_register_form.dart';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CompanyAuthCubit>().state;
    final isLoading = authState.status == AuthStatus.authenticating;
    const background = uiBackground;

    return BlocListener<CompanyAuthCubit, CompanyAuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.needsOnboarding != current.needsOnboarding,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        } else if (state.isAuthenticated == true &&
            state.needsOnboarding == true) {
          context.go('/onboarding');
        }
      },
      child: Scaffold(
        appBar: const AppNavBar(),
        backgroundColor: background,
        body: CompanyRegisterForm(
          isLoading: isLoading,
          onSubmit: _submit,
          onLogin: () => context.go('/CompanyLogin'),
        ),
      ),
    );
  }

  void _submit(String name, String email, String password) {
    context.read<CompanyAuthCubit>().registerCompany(
      name: name,
      email: email,
      password: password,
    );
  }
}
