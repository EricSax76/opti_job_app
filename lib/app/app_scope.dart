import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/bootstrap/app_dependencies.dart';
import 'package:opti_job_app/core/router/app_router.dart';
import 'package:opti_job_app/home/app.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';

class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: dependencies.authRepository),
        RepositoryProvider.value(value: dependencies.jobOfferRepository),
        RepositoryProvider.value(value: dependencies.profileRepository),
        RepositoryProvider.value(value: dependencies.curriculumRepository),
        RepositoryProvider.value(value: dependencies.calendarRepository),
        RepositoryProvider.value(value: dependencies.applicationRepository),
        RepositoryProvider.value(value: dependencies.applicationService),
        RepositoryProvider.value(value: dependencies.aiRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CandidateAuthCubit>(
            create: (_) =>
                CandidateAuthCubit(dependencies.authRepository)..restoreSession(),
          ),
          BlocProvider<CompanyAuthCubit>(
            create: (_) =>
                CompanyAuthCubit(dependencies.authRepository)..restoreSession(),
          ),
          BlocProvider<JobOffersCubit>(
            create: (_) =>
                JobOffersCubit(
                  dependencies.jobOfferRepository,
                  profileRepository: dependencies.profileRepository,
                ),
          ),
          BlocProvider<CalendarCubit>(
            create: (_) =>
                CalendarCubit(dependencies.calendarRepository)
                  ..loadMonth(DateTime.now()),
          ),
          BlocProvider<ProfileCubit>(
            create: (context) => ProfileCubit(
              repository: dependencies.profileRepository,
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
            ),
          ),
          BlocProvider<CurriculumCubit>(
            create: (context) => CurriculumCubit(
              repository: dependencies.curriculumRepository,
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
            ),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<CandidateAuthCubit, CandidateAuthState>(
              listenWhen: (previous, current) =>
                  previous.isAuthenticated != current.isAuthenticated,
              listener: (context, state) {
                if (state.isAuthenticated) {
                  context.read<JobOffersCubit>().loadOffers();
                }
              },
            ),
            BlocListener<CompanyAuthCubit, CompanyAuthState>(
              listenWhen: (previous, current) =>
                  previous.isAuthenticated != current.isAuthenticated,
              listener: (context, state) {
                if (state.isAuthenticated) {
                  context.read<JobOffersCubit>().loadOffers();
                }
              },
            ),
          ],
          child: const _AppRouterHost(),
        ),
      ),
    );
  }
}

class _AppRouterHost extends StatefulWidget {
  const _AppRouterHost();

  @override
  State<_AppRouterHost> createState() => _AppRouterHostState();
}

class _AppRouterHostState extends State<_AppRouterHost> {
  GoRouterCombinedRefreshStream? _routerRefreshStream;
  AppRouter? _appRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appRouter != null) return;

    final refreshStream = GoRouterCombinedRefreshStream(
      context.read<CandidateAuthCubit>(),
      context.read<CompanyAuthCubit>(),
    );
    _routerRefreshStream = refreshStream;
    _appRouter = AppRouter(routerRefreshStream: refreshStream);
  }

  @override
  void dispose() {
    _routerRefreshStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appRouter = _appRouter;
    if (appRouter == null) return const SizedBox.shrink();
    return InfoJobsApp(router: appRouter.router);
  }
}
