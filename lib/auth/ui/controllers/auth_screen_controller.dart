import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_state.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';

class AuthScreenController {
  const AuthScreenController._();

  static void handleCandidateLoginState(
    BuildContext context,
    CandidateAuthState state,
  ) {
    final errorMessage = AuthFormScreenLogic.resolveErrorMessage(
      state.errorMessage,
    );
    if (errorMessage != null) {
      _showErrorMessage(context, errorMessage);
      return;
    }

    final route = AuthFormScreenLogic.candidateLoginNavigation(state);
    if (route != null) context.go(route);
  }

  static void handleCandidateRegisterState(
    BuildContext context,
    CandidateAuthState state,
  ) {
    final errorMessage = AuthFormScreenLogic.resolveErrorMessage(
      state.errorMessage,
    );
    if (errorMessage != null) {
      _showErrorMessage(context, errorMessage);
      return;
    }

    final route = AuthFormScreenLogic.candidateRegisterNavigation(state);
    if (route != null) context.go(route);
  }

  static void handleCompanyLoginState(
    BuildContext context,
    CompanyAuthState state,
  ) {
    final errorMessage = AuthFormScreenLogic.resolveErrorMessage(
      state.errorMessage,
    );
    if (errorMessage != null) {
      _showErrorMessage(context, errorMessage);
      return;
    }

    final route = AuthFormScreenLogic.companyLoginNavigation(state);
    if (route != null) context.go(route);
  }

  static void handleCompanyRegisterState(
    BuildContext context,
    CompanyAuthState state,
  ) {
    final errorMessage = AuthFormScreenLogic.resolveErrorMessage(
      state.errorMessage,
    );
    if (errorMessage != null) {
      _showErrorMessage(context, errorMessage);
      return;
    }

    final route = AuthFormScreenLogic.companyRegisterNavigation(state);
    if (route != null) context.go(route);
  }

  static void handleRecruiterLoginState(
    BuildContext context,
    RecruiterAuthState state,
  ) {
    final errorMessage = AuthFormScreenLogic.resolveErrorMessage(
      state.errorMessage,
    );
    if (errorMessage != null) {
      _showErrorMessage(context, errorMessage);
      return;
    }

    final route = AuthFormScreenLogic.recruiterLoginNavigation(state);
    if (route != null) context.go(route);
  }

  static void handleRecruiterRegisterState(
    BuildContext context,
    RecruiterAuthState state,
  ) {
    final errorMessage = AuthFormScreenLogic.resolveErrorMessage(
      state.errorMessage,
    );
    if (errorMessage != null) {
      _showErrorMessage(context, errorMessage);
      return;
    }

    final route = AuthFormScreenLogic.recruiterRegisterNavigation(state);
    if (route != null) context.go(route);
  }

  static void submitCandidateLogin(
    BuildContext context, {
    required String email,
    required String password,
  }) {
    context.read<CandidateAuthCubit>().loginCandidate(
      email: email,
      password: password,
    );
  }

  static Future<void> submitCandidateGoogleSignIn(BuildContext context) async {
    await context.read<CandidateAuthCubit>().signInWithGoogle();
  }

  static void submitCandidateRegister(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) {
    context.read<CandidateAuthCubit>().registerCandidate(
      name: name,
      email: email,
      password: password,
    );
  }

  static Future<void> submitCandidateWalletSignIn(BuildContext context) async {
    final repository = context.read<AuthRepository>();
    try {
      final input = await repository.buildEudiWalletSignInInputFromNative();
      if (!context.mounted) return;
      context.read<CandidateAuthCubit>().signInWithEudiWallet(input: input);
    } catch (error) {
      if (!context.mounted) return;
      final message = repository.mapException(error).message;
      _showErrorMessage(context, message);
    }
  }

  static void submitCompanyLogin(
    BuildContext context, {
    required String email,
    required String password,
  }) {
    context.read<CompanyAuthCubit>().loginCompany(
      email: email,
      password: password,
    );
  }

  static void submitCompanyRegister(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) {
    context.read<CompanyAuthCubit>().registerCompany(
      name: name,
      email: email,
      password: password,
    );
  }

  static void submitRecruiterLogin(
    BuildContext context, {
    required String email,
    required String password,
  }) {
    context.read<RecruiterAuthCubit>().loginRecruiter(
      email: email,
      password: password,
    );
  }

  static void submitRecruiterRegister(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
  }) {
    context.read<RecruiterAuthCubit>().registerRecruiter(
      name: name,
      email: email,
      password: password,
    );
  }

  static void _showErrorMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
