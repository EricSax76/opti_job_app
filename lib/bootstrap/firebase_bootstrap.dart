import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/firebase_options.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint(
      'Firebase apps: ${Firebase.apps.map((app) => app.name).toList()}',
    );
    debugPrint('Firebase default options: ${Firebase.app().options}');
  }
}

Future<void> maybeActivateFirebaseAppCheck() async {
  const useAppCheck = bool.fromEnvironment(
    'USE_FIREBASE_APP_CHECK',
    defaultValue: false,
  );
  if (!useAppCheck) return;

  if (kDebugMode) debugPrint('[AppCheck] Activating providers');

  final webProvider = kIsWeb
      ? (() {
    const siteKey = String.fromEnvironment(
      'FIREBASE_APP_CHECK_WEB_SITE_KEY',
      defaultValue: '',
    );
    if (siteKey.trim().isEmpty) {
      throw StateError(
        'Missing FIREBASE_APP_CHECK_WEB_SITE_KEY. '
        'Set it with --dart-define=FIREBASE_APP_CHECK_WEB_SITE_KEY=... '
        'or disable App Check with --dart-define=USE_FIREBASE_APP_CHECK=false.',
      );
    }

    const provider = String.fromEnvironment(
      'FIREBASE_APP_CHECK_WEB_PROVIDER',
      defaultValue: 'recaptcha_v3',
    ); // 'recaptcha_v3' | 'recaptcha_enterprise'

    return provider == 'recaptcha_enterprise'
        ? ReCaptchaEnterpriseProvider(siteKey)
        : ReCaptchaV3Provider(siteKey);
  })()
      : null;

  await FirebaseAppCheck.instance.activate(
    webProvider: webProvider,
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );
}

Future<void> maybeUseFirebaseEmulators() async {
  const useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  if (!useFirebaseEmulators) return;

  const authHostEnv = String.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_HOST',
    defaultValue: 'localhost:9099',
  );
  final authHostPort = _parseHostPort(authHostEnv, defaultPort: 9099);

  const firestoreHostEnv = String.fromEnvironment(
    'FIRESTORE_EMULATOR_HOST',
    defaultValue: 'localhost:8080',
  );
  final firestoreHostPort = _parseHostPort(firestoreHostEnv, defaultPort: 8080);

  await FirebaseAuth.instance.useAuthEmulator(
    authHostPort.host,
    authHostPort.port,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    firestoreHostPort.host,
    firestoreHostPort.port,
  );

  if (kDebugMode) {
    debugPrint(
      'Firebase emulators enabled: auth=${authHostPort.host}:${authHostPort.port} '
      'firestore=${firestoreHostPort.host}:${firestoreHostPort.port}',
    );
  }
}

({String host, int port}) _parseHostPort(
  String hostEnv, {
  required int defaultPort,
}) {
  final parts = hostEnv.split(':');
  final host = parts.first;
  final port = parts.length > 1
      ? int.tryParse(parts[1]) ?? defaultPort
      : defaultPort;
  return (host: host, port: port);
}
