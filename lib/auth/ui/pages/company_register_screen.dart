import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/auth/ui/controllers/auth_screen_controller.dart';
import 'package:opti_job_app/core/shell/core_shell.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_register_form.dart';

class CompanyRegisterScreen extends StatelessWidget {
  const CompanyRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CompanyAuthCubit>().state;
    final viewModel = AuthFormScreenLogic.buildViewModel(authState.status);
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<CompanyAuthCubit, CompanyAuthState>(
      listenWhen: AuthFormScreenLogic.shouldListenCompanyRegister,
      listener: AuthScreenController.handleCompanyRegisterState,
      child: CoreShell(
        variant: CoreShellVariant.public,
        backgroundColor: background,
        body: CompanyRegisterForm(
          isLoading: viewModel.isLoading,
          onSubmit: (name, email, password) =>
              AuthScreenController.submitCompanyRegister(
                context,
                name: name,
                email: email,
                password: password,
              ),
          onLogin: () => context.go('/CompanyLogin'),
        ),
      ),
    );
  }
}
