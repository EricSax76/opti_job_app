import 'package:opti_job_app/auth/cubit/auth_status.dart';
import 'package:opti_job_app/auth/cubit/auth_cubit.dart'; // Import the base AuthCubit
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/auth/repositories/auth_repository.dart';

class CompanyAuthCubit extends AuthCubit<CompanyAuthState> {
  final AuthRepository _repository;

  CompanyAuthCubit(this._repository) : super(const CompanyAuthState());

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
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo iniciar sesión.',
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
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo completar el registro.',
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
}
