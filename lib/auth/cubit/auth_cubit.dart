import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/auth/cubit/auth_status.dart';

abstract class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.errorMessage,
    required this.needsOnboarding,
  });

  final AuthStatus status;
  final String? errorMessage;
  final bool needsOnboarding;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isCandidate;
  bool get isCompany;

  @override
  List<Object?> get props => [status, errorMessage, needsOnboarding];
}

abstract class AuthCubit extends Cubit<AuthState> {
  AuthCubit(super.initialState);

  // Common authentication methods can be defined here if needed.
  // For now, it will primarily serve as a type.
}
