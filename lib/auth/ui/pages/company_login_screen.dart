import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/auth/ui/controllers/auth_screen_controller.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_login_form.dart';

class CompanyLoginScreen extends StatelessWidget {
  const CompanyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CompanyAuthCubit>().state;
    final viewModel = AuthFormScreenLogic.buildViewModel(authState.status);
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<CompanyAuthCubit, CompanyAuthState>(
      listenWhen: AuthFormScreenLogic.shouldListenCompanyLogin,
      listener: AuthScreenController.handleCompanyLoginState,
      child: CoreShell(
        variant: CoreShellVariant.public,
        backgroundColor: background,
        body: CompanyLoginForm(
          isLoading: viewModel.isLoading,
          onSubmit: (email, password) =>
              AuthScreenController.submitCompanyLogin(
                context,
                email: email,
                password: password,
              ),
          onRegister: () => context.go('/companyregister'),
        ),
      ),
    );
  }
}
