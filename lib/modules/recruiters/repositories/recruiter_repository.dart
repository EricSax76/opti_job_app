import 'package:opti_job_app/modules/recruiters/models/invitation.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

/// Contrato de acceso a datos del módulo de reclutadores.
abstract class RecruiterRepository {
  /// Obtiene el reclutador asociado a [uid]. Devuelve `null` si no existe.
  Future<Recruiter?> getRecruiter(String uid);

  /// Genera un código de invitación para un nuevo miembro del equipo.
  Future<String> createInvitation({required RecruiterRole role, String? email});

  /// Acepta un código de invitación para asociar al reclutador actual a empresa.
  Future<void> acceptInvitation({required String code, required String name});

  /// Actualiza el rol de un reclutador existente.
  Future<void> updateRecruiterRole(String uid, RecruiterRole role);

  /// Deshabilita un reclutador (status → disabled).
  Future<void> removeRecruiter(String uid);

  /// Stream de reclutadores activos/invitados de una empresa.
  Stream<List<Recruiter>> watchCompanyRecruiters(String companyId);

  /// Obtiene una invitación por código. Devuelve `null` si no existe.
  Future<Invitation?> getInvitation(String code);
}
