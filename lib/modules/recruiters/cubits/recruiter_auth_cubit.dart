import 'dart:async';

import 'package:opti_job_app/auth/cubits/auth_cubit.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_state.dart';

/// Cubit que gestiona la sesión de un reclutador.
///
/// Escucha el stream de UID de Firebase Auth para detectar cierres de sesión
/// externos (ej. token revocado), igual que [CompanyAuthCubit].
class RecruiterAuthCubit extends AuthCubit<RecruiterAuthState> {
  RecruiterAuthCubit(this._repository) : super(const RecruiterAuthState()) {
    _authSubscription = _repository.uidStream.listen((uid) {
      final currentUid = state.recruiter?.uid;
      if (!state.isAuthenticated || currentUid == null) return;
      if (uid == null || uid != currentUid) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearRecruiter: true,
            clearError: true,
          ),
        );
      }
    });
  }

  final AuthRepository _repository;
  StreamSubscription<String?>? _authSubscription;

  // ─── Sesión ───────────────────────────────────────────────────────────────

  /// Restaura la sesión desde Firebase Auth + Firestore al iniciar la app.
  Future<void> restoreSession() async {
    if (state.isAuthenticated) return;

    try {
      final recruiter = await _repository.restoreRecruiterSession();
      if (recruiter == null) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearRecruiter: true,
            clearError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          recruiter: recruiter,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearRecruiter: true,
          clearError: true,
        ),
      );
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<void> loginRecruiter({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final recruiter = await _repository.loginRecruiter(
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          recruiter: recruiter,
          clearError: true,
        ),
      );
    } catch (error) {
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
          clearRecruiter: true,
        ),
      );
    }
  }

  // ─── Registro libre ─────────────────────────────────────────────────────

  Future<void> registerRecruiter({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final recruiter = await _repository.registerRecruiter(
        name: name,
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          recruiter: recruiter,
          clearError: true,
        ),
      );
    } catch (error) {
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
          clearRecruiter: true,
        ),
      );
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // La sesión local se limpia igualmente.
    }
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearRecruiter: true,
        clearError: true,
      ),
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
