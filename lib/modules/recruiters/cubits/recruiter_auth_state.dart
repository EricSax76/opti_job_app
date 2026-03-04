import 'package:opti_job_app/auth/cubits/auth_cubit.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';

/// Estado de autenticación de un reclutador.
///
/// Extiende [AuthState] para integrarse con el sistema de auth existente
/// y con [GoRouterCombinedRefreshStream].
class RecruiterAuthState extends AuthState {
  const RecruiterAuthState({
    super.status = AuthStatus.unknown,
    this.recruiter,
    super.errorMessage,
  }) : super(needsOnboarding: false); // Los reclutadores no tienen onboarding

  final Recruiter? recruiter;

  // ─── AuthState overrides ─────────────────────────────────────────────────

  @override
  bool get isCandidate => false;

  @override
  bool get isCompany => false;

  /// Identifica a este estado como perteneciente a un reclutador.
  bool get isRecruiter => true;

  @override
  List<Object?> get props => [...super.props, recruiter];

  // ─── copyWith ─────────────────────────────────────────────────────────────

  RecruiterAuthState copyWith({
    AuthStatus? status,
    Recruiter? recruiter,
    String? errorMessage,
    bool clearRecruiter = false,
    bool clearError = false,
  }) {
    return RecruiterAuthState(
      status: status ?? this.status,
      recruiter: clearRecruiter ? null : recruiter ?? this.recruiter,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
