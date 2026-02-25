import 'dart:async';

import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/cubits/auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

class CompanyAuthCubit extends AuthCubit<CompanyAuthState> {
  final AuthRepository _repository;
  StreamSubscription<String?>? _authSubscription;

  CompanyAuthCubit(this._repository) : super(const CompanyAuthState()) {
    _authSubscription = _repository.uidStream.listen((uid) {
      final currentCompanyUid = state.company?.uid;
      if (!state.isAuthenticated || currentCompanyUid == null) return;
      if (uid == null || uid != currentCompanyUid) {
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

    try {
      final company = await _repository.restoreCompanySession();
      if (company == null) {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            clearCompany: true,
            clearError: true,
            needsOnboarding: false,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          company: company,
          needsOnboarding: _needsOnboarding(company),
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearCompany: true,
          clearError: true,
          needsOnboarding: false,
        ),
      );
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
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          company: company,
          needsOnboarding: _needsOnboarding(company),
        ),
      );
    } catch (error) {
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
          clearCompany: true,
        ),
      );
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
          needsOnboarding: _needsOnboarding(company),
        ),
      );
    } catch (error) {
      final authException = _repository.mapException(error);
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: authException.message,
          clearCompany: true,
        ),
      );
    }
  }

  void completeOnboarding() {
    if (!state.needsOnboarding) return;
    emit(state.copyWith(needsOnboarding: false));
    final uid = state.company?.uid;
    if (uid != null && uid.isNotEmpty) {
      unawaited(_repository.completeCompanyOnboarding(uid));
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

  bool _needsOnboarding(Company company) {
    return !company.onboardingCompleted;
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
