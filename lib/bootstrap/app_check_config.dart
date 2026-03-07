import 'package:flutter/foundation.dart';
import 'package:opti_job_app/bootstrap/web_runtime_config.dart';

bool isFirebaseAppCheckEnabled() {
  const envValue = bool.fromEnvironment(
    'USE_FIREBASE_APP_CHECK',
    defaultValue: false,
  );
  if (envValue) return true;
  if (!kIsWeb) return false;

  return _parseBool(readWebRuntimeConfigValue('USE_FIREBASE_APP_CHECK')) ??
      false;
}

String resolveFirebaseAppCheckWebSiteKey() {
  const envValue = String.fromEnvironment(
    'FIREBASE_APP_CHECK_WEB_SITE_KEY',
    defaultValue: '',
  );
  final normalizedEnvValue = envValue.trim();
  if (normalizedEnvValue.isNotEmpty) return normalizedEnvValue;
  if (!kIsWeb) return '';

  final runtimeValue = readWebRuntimeConfigValue(
    'FIREBASE_APP_CHECK_WEB_SITE_KEY',
  )?.trim();
  return runtimeValue ?? '';
}

String resolveFirebaseAppCheckWebProvider() {
  const envValue = String.fromEnvironment(
    'FIREBASE_APP_CHECK_WEB_PROVIDER',
    defaultValue: '',
  );
  final normalizedEnvValue = envValue.trim();
  if (normalizedEnvValue.isNotEmpty) return normalizedEnvValue;
  if (!kIsWeb) return 'recaptcha_v3';

  final runtimeValue = readWebRuntimeConfigValue(
    'FIREBASE_APP_CHECK_WEB_PROVIDER',
  )?.trim();
  if (runtimeValue == null || runtimeValue.isEmpty) {
    return 'recaptcha_v3';
  }
  return runtimeValue;
}

bool? _parseBool(String? value) {
  final normalized = value?.trim().toLowerCase();
  switch (normalized) {
    case '1':
    case 't':
    case 'true':
    case 'y':
    case 'yes':
    case 'on':
      return true;
    case '0':
    case 'f':
    case 'false':
    case 'n':
    case 'no':
    case 'off':
      return false;
    default:
      return null;
  }
}
