
class FeatureFlags {
  // Prevent instantiation
  const FeatureFlags._();

  static const bool interviews = true;

  // Placeholder for future Remote Config integration
  static Future<void> initialize() async {
    // await FirebaseRemoteConfig.instance.fetchAndActivate();
  }
}
