/// Roles disponibles para un reclutador dentro de una empresa.
enum RecruiterRole {
  /// Puede todo: gestionar equipo, crear invitaciones, gestionar ofertas y puntuar.
  admin,

  /// Puede gestionar ofertas y puntuar candidatos, pero no gestionar equipo.
  recruiter,

  /// Responsable técnico del área, enfocado en feedback/evaluación.
  hiringManager,

  /// Evaluador temporal externo con permisos mínimos de evaluación.
  externalEvaluator,

  /// Solo puede ver información; sin capacidad de edición.
  viewer;

  /// Convierte la cadena de Firestore al enum.
  static RecruiterRole fromString(String value) {
    return switch (value) {
      'admin' => RecruiterRole.admin,
      'recruiter' => RecruiterRole.recruiter,
      'hiring_manager' => RecruiterRole.hiringManager,
      'hiringmanager' => RecruiterRole.hiringManager,
      'external_evaluator' => RecruiterRole.externalEvaluator,
      'externalevaluator' => RecruiterRole.externalEvaluator,
      'viewer' => RecruiterRole.viewer,
      _ => RecruiterRole.viewer, // valor por defecto seguro
    };
  }

  /// Cadena que se almacena en Firestore.
  String toFirestoreString() {
    return switch (this) {
      RecruiterRole.admin => 'admin',
      RecruiterRole.recruiter => 'recruiter',
      RecruiterRole.hiringManager => 'hiring_manager',
      RecruiterRole.externalEvaluator => 'external_evaluator',
      RecruiterRole.viewer => 'viewer',
    };
  }
}
