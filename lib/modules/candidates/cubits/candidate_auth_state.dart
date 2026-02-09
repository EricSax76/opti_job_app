import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/auth/cubits/auth_cubit.dart'; // Import the base AuthState

class CandidateAuthState extends AuthState {
  const CandidateAuthState({
    super.status = AuthStatus.unauthenticated,
    this.candidate,
    super.errorMessage,
    super.needsOnboarding = false,
  });

  final Candidate? candidate;

  @override
  bool get isCandidate => true;

  @override
  bool get isCompany => false;

  @override
  List<Object?> get props => [...super.props, candidate];

  CandidateAuthState copyWith({
    AuthStatus? status,
    Candidate? candidate,
    String? errorMessage,
    bool? needsOnboarding,
    bool clearCandidate = false,
    bool clearError = false,
  }) {
    return CandidateAuthState(
      status: status ?? this.status,
      candidate: clearCandidate ? null : candidate ?? this.candidate,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    );
  }
}
