import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/app/app_scope.dart';
import 'package:opti_job_app/bootstrap/app_dependencies.dart';
import 'package:opti_job_app/bootstrap/firebase_bootstrap.dart';
import 'package:opti_job_app/home/models/app_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  await maybeActivateFirebaseAppCheck();
  await maybeUseFirebaseEmulators();
  Bloc.observer = const AppBlocObserver();

  final dependencies = AppDependencies.create();

  runApp(AppScope(dependencies: dependencies));
}
