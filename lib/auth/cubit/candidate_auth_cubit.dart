import 'package:opti_job_app/data/repositories/auth_repository.dart';
import 'package:opti_job_app/auth/cubit/auth_status.dart';
import 'package:opti_job_app/auth/cubit/auth_cubit.dart'; // Import the base AuthCubit
import 'package:opti_job_app/auth/cubit/candidate_auth_state.dart';

class CandidateAuthCubit extends AuthCubit {
  CandidateAuthCubit(this._repository) : super(const CandidateAuthState());

  final AuthRepository _repository;

  @override
  CandidateAuthState get state => super.state as CandidateAuthState;

  Future<void> loginCandidate({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final candidate = await _repository.loginCandidate(
        email: email,
        password: password,
      );
      emit(
        state.copyWith(status: AuthStatus.authenticated, candidate: candidate),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo iniciar sesión. Verifica tus credenciales.',
          clearCandidate: true,
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
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
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
          needsOnboarding: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo completar el registro.',
          clearCandidate: true,
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
        clearError: true,
        needsOnboarding: false,
      ),
    );
  }
}
