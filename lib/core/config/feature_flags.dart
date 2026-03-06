class FeatureFlags {
  // Prevent instantiation
  const FeatureFlags._();

  static const bool interviews = true;

  /// Activa el módulo de multi-usuario y RBAC para reclutadores.
  ///
  /// Para desactivarlo puntualmente: `--dart-define=RECRUITER_MODULE=false`
  static const bool recruiterModule = bool.fromEnvironment(
    'RECRUITER_MODULE',
    defaultValue: true,
  );

  // Placeholder for future Remote Config integration
  static Future<void> initialize() async {
    // await FirebaseRemoteConfig.instance.fetchAndActivate();
  }
}
