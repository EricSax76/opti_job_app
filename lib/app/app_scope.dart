import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/bootstrap/app_dependencies.dart';
import 'package:opti_job_app/core/router/app_router.dart';
import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/home/app.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_state.dart';

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
        RepositoryProvider.value(value: dependencies.companiesRepository),
        RepositoryProvider.value(value: dependencies.applicantsRepository),
        RepositoryProvider.value(value: dependencies.curriculumRepository),
        RepositoryProvider.value(value: dependencies.cvAnalysisService),
        RepositoryProvider.value(value: dependencies.calendarRepository),
        RepositoryProvider.value(value: dependencies.applicationRepository),
        RepositoryProvider.value(value: dependencies.applicationService),
        RepositoryProvider.value(value: dependencies.aiService),
        RepositoryProvider.value(value: dependencies.aiRepository),
        RepositoryProvider.value(value: dependencies.coverLetterRepository),
        RepositoryProvider.value(value: dependencies.videoCurriculumRepository),
        RepositoryProvider.value(value: dependencies.interviewRepository),
        RepositoryProvider.value(value: dependencies.evaluationRepository),
        RepositoryProvider.value(value: dependencies.dataRequestRepository),
        RepositoryProvider.value(value: dependencies.consentRepository),
        RepositoryProvider.value(value: dependencies.salaryBenchmarkRepository),
        RepositoryProvider.value(value: dependencies.analyticsRepository),
        RepositoryProvider.value(value: dependencies.firebaseAuth),
        // Fase 0 RBAC
        RepositoryProvider.value(value: dependencies.recruiterRepository),
        RepositoryProvider.value(value: dependencies.invitationService),
        RepositoryProvider.value(value: dependencies.rbacService),
        RepositoryProvider.value(value: dependencies.talentPoolRepository),
        RepositoryProvider.value(value: dependencies.pipelineRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<CandidateAuthCubit>(
            create: (_) =>
                CandidateAuthCubit(dependencies.authRepository)
                  ..restoreSession(),
          ),
          BlocProvider<CompanyAuthCubit>(
            create: (_) =>
                CompanyAuthCubit(dependencies.authRepository)..restoreSession(),
          ),
          // Fase 0 RBAC
          BlocProvider<RecruiterAuthCubit>(
            create: (_) =>
                RecruiterAuthCubit(dependencies.authRepository)
                  ..restoreSession(),
          ),
          BlocProvider<JobOffersCubit>(
            create: (_) => JobOffersCubit(
              dependencies.jobOfferRepository,
              profileRepository: dependencies.profileRepository,
            ),
          ),
          BlocProvider<ProfileCubit>(
            create: (context) => ProfileCubit(
              repository: dependencies.profileRepository,
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
            )..start(),
          ),
          BlocProvider<CurriculumCubit>(
            create: (context) => CurriculumCubit(
              repository: dependencies.curriculumRepository,
              candidateAuthCubit: context.read<CandidateAuthCubit>(),
            )..start(),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<CandidateAuthCubit, CandidateAuthState>(
              listenWhen: (previous, current) =>
                  previous.isAuthenticated != current.isAuthenticated,
              listener: (context, state) {
                if (state.isAuthenticated) {
                  context.read<JobOffersCubit>().refresh();
                }
              },
            ),
            BlocListener<CompanyAuthCubit, CompanyAuthState>(
              listenWhen: (previous, current) =>
                  previous.isAuthenticated != current.isAuthenticated,
              listener: (context, state) {
                if (state.isAuthenticated) {
                  context.read<JobOffersCubit>().refresh();
                }
              },
            ),
            BlocListener<RecruiterAuthCubit, RecruiterAuthState>(
              listenWhen: (previous, current) =>
                  previous.isAuthenticated != current.isAuthenticated,
              listener: (context, state) {
                if (state.isAuthenticated) {
                  context.read<JobOffersCubit>().refresh();
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
      context.read<RecruiterAuthCubit>(),
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
