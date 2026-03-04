/// Roles disponibles para un reclutador dentro de una empresa.
enum RecruiterRole {
  /// Puede todo: gestionar equipo, crear invitaciones, gestionar ofertas y puntuar.
  admin,

  /// Puede gestionar ofertas y puntuar candidatos, pero no gestionar equipo.
  recruiter,

  /// Solo puede ver información; sin capacidad de edición.
  viewer;

  /// Convierte la cadena de Firestore al enum.
  static RecruiterRole fromString(String value) {
    return switch (value) {
      'admin' => RecruiterRole.admin,
      'recruiter' => RecruiterRole.recruiter,
      'viewer' => RecruiterRole.viewer,
      _ => RecruiterRole.viewer, // valor por defecto seguro
    };
  }

  /// Cadena que se almacena en Firestore.
  String toFirestoreString() {
    return switch (this) {
      RecruiterRole.admin => 'admin',
      RecruiterRole.recruiter => 'recruiter',
      RecruiterRole.viewer => 'viewer',
    };
  }
}
