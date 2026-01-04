import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:opti_job_app/auth/cubit/auth_status.dart';
import 'package:opti_job_app/auth/cubit/auth_cubit.dart'; // Import the base AuthCubit
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

class CompanyAuthCubit extends AuthCubit<CompanyAuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  CompanyAuthCubit(this._repository) : super(const CompanyAuthState()) {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      final currentCompanyUid = state.company?.uid;
      if (!state.isAuthenticated || currentCompanyUid == null) return;
      if (user == null || user.uid != currentCompanyUid) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearCompany: true,
            clearError: true,
            needsOnboarding: false,
          ),
        );
      }
    });
  }

  Future<void> restoreSession() async {
    if (state.isAuthenticated) return;

    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final company = await _repository.restoreCompanySession();
      if (company == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      emit(state.copyWith(status: AuthStatus.authenticated, company: company));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Auth] restoreSession (company) failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> loginCompany({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final company = await _repository.loginCompany(
        email: email,
        password: password,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, company: company));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Auth] loginCompany failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _userFacingAuthErrorMessage(error),
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
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
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
          needsOnboarding: true,
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Auth] registerCompany failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: _userFacingAuthErrorMessage(error),
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
        clearCompany: true,
        clearError: true,
        needsOnboarding: false,
      ),
    );
  }

  void updateCompany(Company company) {
    if (!state.isAuthenticated) return;
    emit(state.copyWith(company: company));
  }

  String _userFacingAuthErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Email inválido.';
        case 'user-disabled':
          return 'Tu cuenta está deshabilitada.';
        case 'user-not-found':
          return 'Usuario no encontrado.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'invalid-credential':
          return 'Credenciales inválidas.';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde.';
        case 'network-request-failed':
          return 'Error de red. Revisa tu conexión.';
        default:
          return error.message ?? 'No se pudo iniciar sesión.';
      }
    }

    if (error is FirebaseException) {
      if (error.plugin == 'cloud_firestore' && error.code == 'permission-denied') {
        return 'Permiso denegado al leer tu perfil. '
            'Si tienes App Check habilitado/enforced en Firestore, '
            'actívalo en la app (--dart-define=USE_FIREBASE_APP_CHECK=true) '
            'y registra el debug token en Firebase Console.';
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'Ocurrió un error. Intenta nuevamente.';
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
