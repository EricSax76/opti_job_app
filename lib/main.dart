import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/data/repositories/application_repository.dart';
import 'package:opti_job_app/data/services/application_service.dart';

import 'package:opti_job_app/home/app.dart';
import 'package:opti_job_app/home/app_observer.dart';
import 'package:opti_job_app/data/repositories/auth_repository.dart';
import 'package:opti_job_app/data/repositories/calendar_repository.dart';
import 'package:opti_job_app/data/repositories/job_offer_repository.dart';
import 'package:opti_job_app/data/repositories/profile_repository.dart';
import 'package:opti_job_app/data/services/auth_service.dart';
import 'package:opti_job_app/data/services/job_offer_service.dart';
import 'package:opti_job_app/data/services/profile_service.dart';
import 'package:opti_job_app/auth/cubit/candidate_auth_cubit.dart';
import 'package:opti_job_app/auth/cubit/company_auth_cubit.dart';
import 'package:opti_job_app/features/calendar/cubit/calendar_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offers_cubit.dart';
import 'package:opti_job_app/features/profiles/cubit/profile_cubit.dart';
import 'package:opti_job_app/firebase_options.dart';
import 'package:opti_job_app/core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  final applicationRepository = ApplicationRepository(
    firestore: FirebaseFirestore.instance,
  );
  final applicationService = ApplicationService(
    applicationRepository: applicationRepository,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: jobOfferRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: calendarRepository),
        RepositoryProvider.value(value: applicationRepository),
        RepositoryProvider.value(value: applicationService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CandidateAuthCubit>(create: (_) => CandidateAuthCubit(authRepository)),
          BlocProvider<CompanyAuthCubit>(create: (_) => CompanyAuthCubit(authRepository)),
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
              candidateAuthCubit: context.read<CandidateAuthCubit>(), // Updated dependency
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            final appRouter = AppRouter(
              candidateAuthCubit: context.read<CandidateAuthCubit>(), // Updated dependency
              companyAuthCubit: context.read<CompanyAuthCubit>(), // New dependency
            );
            return InfoJobsApp(router: appRouter.router);
          },
        ),
      ),
    ),
  );
}
