import 'package:opti_job_app/modules/recruiters/models/invitation.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

/// Contrato de acceso a datos del módulo de reclutadores.
abstract class RecruiterRepository {
  /// Obtiene el reclutador asociado a [uid]. Devuelve `null` si no existe.
  Future<Recruiter?> getRecruiter(String uid);

  /// Escribe un documento reclutador nuevo. Solo debe llamarse desde servicios
  /// internos (ej. al aceptar una invitación client-side en modo emulador).
  Future<void> createRecruiter(Recruiter recruiter);

  /// Actualiza el rol de un reclutador existente.
  Future<void> updateRecruiterRole(String uid, RecruiterRole role);

  /// Deshabilita un reclutador (status → disabled).
  Future<void> disableRecruiter(String uid);

  /// Stream de reclutadores activos/invitados de una empresa.
  Stream<List<Recruiter>> watchCompanyRecruiters(String companyId);

  /// Obtiene una invitación por código. Devuelve `null` si no existe.
  Future<Invitation?> getInvitation(String code);
}
