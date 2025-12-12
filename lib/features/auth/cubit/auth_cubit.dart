import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:infojobs_flutter_app/data/models/candidate.dart';
import 'package:infojobs_flutter_app/data/models/company.dart';
import 'package:infojobs_flutter_app/data/repositories/auth_repository.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  failure,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.candidate,
    this.company,
    this.errorMessage,
    this.needsOnboarding = false,
  });

  final AuthStatus status;
  final Candidate? candidate;
  final Company? company;
  final String? errorMessage;
  final bool needsOnboarding;

  bool get isAuthenticated => candidate != null || company != null;
  bool get isCandidate => candidate != null;
  bool get isCompany => company != null;

  AuthState copyWith({
    AuthStatus? status,
    Candidate? candidate,
    Company? company,
    String? errorMessage,
    bool? needsOnboarding,
    bool clearCandidate = false,
    bool clearCompany = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      candidate: clearCandidate ? null : candidate ?? this.candidate,
      company: clearCompany ? null : company ?? this.company,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> loginCandidate({
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        clearCompany: true,
      ),
    );
    try {
      final candidate = await _repository.loginCandidate(
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          candidate: candidate,
          clearCompany: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo iniciar sesión. Verifica tus credenciales.',
          clearCandidate: true,
          clearCompany: true,
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> registerCandidate({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        clearCompany: true,
      ),
    );
    try {
      final candidate = await _repository.registerCandidate(
        name: name,
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          candidate: candidate,
          clearCompany: true,
          needsOnboarding: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo completar el registro.',
          clearCandidate: true,
          clearCompany: true,
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> loginCompany({
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        clearCandidate: true,
      ),
    );
    try {
      final company = await _repository.loginCompany(
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          company: company,
          clearCandidate: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo iniciar sesión.',
          clearCandidate: true,
          clearCompany: true,
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> registerCompany({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(
      state.copyWith(
        status: AuthStatus.authenticating,
        clearError: true,
        clearCandidate: true,
      ),
    );
    try {
      final company = await _repository.registerCompany(
        name: name,
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          company: company,
          clearCandidate: true,
          needsOnboarding: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo completar el registro.',
          clearCandidate: true,
          clearCompany: true,
        ),
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  void completeOnboarding() {
    if (state.needsOnboarding) {
      emit(state.copyWith(needsOnboarding: false));
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Ignored: the UI will still clear the local session state.
    }
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearCandidate: true,
        clearCompany: true,
        clearError: true,
        needsOnboarding: false,
      ),
    );
  }
}
