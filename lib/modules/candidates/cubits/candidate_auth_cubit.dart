import 'dart:async';

import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/cubits/auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/auth/models/eudi_wallet_models.dart';

class CandidateAuthCubit extends AuthCubit<CandidateAuthState> {
  final AuthRepository _repository;
  StreamSubscription<String?>? _authSubscription;

  CandidateAuthCubit(this._repository) : super(const CandidateAuthState()) {
    _authSubscription = _repository.uidStream.listen((uid) {
      final currentCandidateUid = state.candidate?.uid;
      if (!state.isAuthenticated || currentCandidateUid == null) return;
      if (uid == null || uid != currentCandidateUid) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearCandidate: true,
            clearError: true,
            needsOnboarding: false,
          ),
        );
      }
    });
  }

  Future<void> restoreSession() async {
    if (state.isAuthenticated) return;

    try {
      final candidate = await _repository.restoreCandidateSession();
      if (candidate == null) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearCandidate: true,
            clearError: true,
            needsOnboarding: false,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          candidate: candidate,
          needsOnboarding: _needsOnboarding(candidate),
          clearError: true,
        ),
      );
    } catch (_) {
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
        state.copyWith(
          status: AuthStatus.authenticated,
          candidate: candidate,
          needsOnboarding: _needsOnboarding(candidate),
        ),
      );
    } catch (error) {
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
          clearCandidate: true,
        ),
      );
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
          needsOnboarding: _needsOnboarding(candidate),
        ),
      );
    } catch (error) {
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
          clearCandidate: true,
        ),
      );
    }
  }

  Future<void> signInWithEudiWallet({
    required EudiWalletSignInInput input,
  }) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final candidate = await _repository.signInCandidateWithEudiWallet(
        input: input,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          candidate: candidate,
          needsOnboarding: _needsOnboarding(candidate),
        ),
      );
    } catch (error) {
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
          clearCandidate: true,
        ),
      );
    }
  }

  void completeOnboarding() {
    if (!state.needsOnboarding) return;
    emit(state.copyWith(needsOnboarding: false));
    final uid = state.candidate?.uid;
    if (uid != null && uid.isNotEmpty) {
      unawaited(_repository.completeCandidateOnboarding(uid));
    }
  }

  bool _needsOnboarding(Candidate candidate) {
    return !candidate.onboardingCompleted;
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

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
