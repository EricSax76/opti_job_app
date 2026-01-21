import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:opti_job_app/auth/cubit/auth_status.dart';
import 'package:opti_job_app/auth/cubit/auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';

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

    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final candidate = await _repository.restoreCandidateSession();
      if (candidate == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      emit(
        state.copyWith(status: AuthStatus.authenticated, candidate: candidate),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Auth] restoreSession failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(state.copyWith(status: AuthStatus.unauthenticated));
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
        state.copyWith(status: AuthStatus.authenticated, candidate: candidate),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Auth] loginCandidate failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
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
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Auth] registerCandidate failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
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

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
