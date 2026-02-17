import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/auth/logic/auth_form_screen_logic.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';

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

  static void _showErrorMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
