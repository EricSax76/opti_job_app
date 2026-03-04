import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

/// Servicio sin estado que evalúa permisos RBAC de un reclutador.
///
/// Diseñado para ser inyectado como singleton vía GetIt y consultado
/// en la capa de presentación antes de mostrar acciones o navegar a rutas.
///
/// ## Tabla de permisos
/// | Permiso            | admin | recruiter | viewer |
/// |--------------------|-------|-----------|--------|
/// | canManageOffers    | ✅    | ✅        | ❌     |
/// | canScore           | ✅    | ✅        | ❌     |
/// | canViewReports     | ✅    | ✅        | ✅     |
/// | canManageTeam      | ✅    | ❌        | ❌     |
/// | canInviteMembers   | ✅    | ❌        | ❌     |
class RbacService {
  const RbacService();

  static const _manageRoles = {RecruiterRole.admin, RecruiterRole.recruiter};
  static const _adminOnly = {RecruiterRole.admin};

  /// Puede crear, editar y cerrar ofertas de trabajo.
  bool canManageOffers(Recruiter? recruiter) =>
      _has(recruiter, _manageRoles);

  /// Puede puntuar y comentar candidatos en el pipeline ATS.
  bool canScore(Recruiter? recruiter) =>
      _has(recruiter, _manageRoles);

  /// Puede ver métricas, pipeline y reportes de analytics.
  bool canViewReports(Recruiter? recruiter) =>
      recruiter != null && recruiter.isActive;

  /// Puede cambiar roles, deshabilitar miembros y gestionar el equipo.
  bool canManageTeam(Recruiter? recruiter) =>
      _has(recruiter, _adminOnly);

  /// Puede generar y compartir códigos de invitación.
  bool canInviteMembers(Recruiter? recruiter) =>
      _has(recruiter, _adminOnly);

  bool _has(Recruiter? recruiter, Set<RecruiterRole> allowed) {
    if (recruiter == null || !recruiter.isActive) return false;
    return allowed.contains(recruiter.role);
  }
}
