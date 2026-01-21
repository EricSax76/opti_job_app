import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/cubits/auth_cubit.dart'; // Import the base AuthState

class CompanyAuthState extends AuthState {
  const CompanyAuthState({
    super.status = AuthStatus.unauthenticated,
    this.company,
    super.errorMessage,
    super.needsOnboarding = false,
  });

  final Company? company;

  @override
  bool get isCandidate => false;

  @override
  bool get isCompany => true;

  @override
  List<Object?> get props => [
    super.props, // Include properties from the base class
    company,
  ];

  CompanyAuthState copyWith({
    AuthStatus? status,
    Company? company,
    String? errorMessage,
    bool? needsOnboarding,
    bool clearCompany = false,
    bool clearError = false,
  }) {
    return CompanyAuthState(
      status: status ?? this.status,
      company: clearCompany ? null : company ?? this.company,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    );
  }
}
