import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:infojobs_flutter_app/app.dart';
import 'package:infojobs_flutter_app/app_observer.dart';
import 'package:infojobs_flutter_app/data/repositories/auth_repository.dart';
import 'package:infojobs_flutter_app/data/repositories/calendar_repository.dart';
import 'package:infojobs_flutter_app/data/repositories/job_offer_repository.dart';
import 'package:infojobs_flutter_app/data/repositories/profile_repository.dart';
import 'package:infojobs_flutter_app/data/services/auth_service.dart';
import 'package:infojobs_flutter_app/data/services/job_offer_service.dart';
import 'package:infojobs_flutter_app/data/services/profile_service.dart';
import 'package:infojobs_flutter_app/features/auth/cubit/auth_cubit.dart';
import 'package:infojobs_flutter_app/features/calendar/cubit/calendar_cubit.dart';
import 'package:infojobs_flutter_app/features/job_offers/cubit/job_offers_cubit.dart';
import 'package:infojobs_flutter_app/features/profiles/cubit/profile_cubit.dart';
import 'package:infojobs_flutter_app/firebase_options.dart';
import 'package:infojobs_flutter_app/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  const useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  if (useFirebaseEmulators) {
    const authHostEnv = String.fromEnvironment(
      'FIREBASE_AUTH_EMULATOR_HOST',
      defaultValue: 'localhost:9099',
    );
    final authHostParts = authHostEnv.split(':');
    final authHost = authHostParts.first;
    final authPort = authHostParts.length > 1
        ? int.tryParse(authHostParts[1]) ?? 9099
        : 9099;
    const firestoreHostEnv = String.fromEnvironment(
      'FIRESTORE_EMULATOR_HOST',
      defaultValue: 'localhost:8080',
    );
    final firestoreHostParts = firestoreHostEnv.split(':');
    final firestoreHost = firestoreHostParts.first;
    final firestorePort = firestoreHostParts.length > 1
        ? int.tryParse(firestoreHostParts[1]) ?? 8080
        : 8080;

    await FirebaseAuth.instance.useAuthEmulator(authHost, authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(
      firestoreHost,
      firestorePort,
    );
  }
  Bloc.observer = const AppBlocObserver();

  final authRepository = AuthRepository(AuthService());
  final jobOfferRepository = JobOfferRepository(JobOfferService());
  final profileRepository = ProfileRepository(ProfileService());
  final calendarRepository = CalendarRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: jobOfferRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: calendarRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(create: (_) => AuthCubit(authRepository)),
          BlocProvider<JobOffersCubit>(
            create: (_) => JobOffersCubit(jobOfferRepository)..loadOffers(),
          ),
          BlocProvider<CalendarCubit>(
            create: (_) =>
                CalendarCubit(calendarRepository)..loadMonth(DateTime.now()),
          ),
          BlocProvider<ProfileCubit>(
            create: (context) => ProfileCubit(
              repository: profileRepository,
              authCubit: context.read<AuthCubit>(),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            final appRouter = AppRouter(authCubit: context.read<AuthCubit>());
            return InfoJobsApp(router: appRouter.router);
          },
        ),
      ),
    ),
  );
}
