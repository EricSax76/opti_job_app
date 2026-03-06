import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/features/calendar/cubits/calendar_cubit.dart';
import 'package:opti_job_app/features/calendar/repositories/calendar_repository.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/pages/candidate_dashboard_screen.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_cubit.dart';
import 'package:opti_job_app/modules/curriculum/cubits/curriculum_form_cubit.dart';
import 'package:opti_job_app/modules/curriculum/services/cv_analysis_service.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/modules/compliance/cubits/data_requests_cubit.dart';
import 'package:opti_job_app/modules/compliance/repositories/compliance_repository.dart';
import 'package:opti_job_app/modules/compliance/ui/pages/candidate_privacy_portal_screen.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

List<RouteBase> buildCandidateRoutes() {
  return [
    GoRoute(
      path: '/CandidateDashboard',
      name: 'candidate-dashboard-legacy',
      builder: (context, state) {
        final uid =
            context.read<CandidateAuthCubit>().state.candidate?.uid ?? '';
        return _buildCandidateDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 0,
        );
      },
    ),
    GoRoute(
      path: '/candidate/:uid/dashboard',
      name: 'candidate-dashboard',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCandidateDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 0,
        );
      },
    ),
    GoRoute(
      path: '/candidate/:uid/applications',
      name: 'candidate-applications',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCandidateDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 1,
        );
      },
    ),
    GoRoute(
      path: '/candidate/:uid/interviews',
      name: 'candidate-interviews',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCandidateDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 2,
        );
      },
    ),
    GoRoute(
      path: '/candidate/:uid/cv',
      name: 'candidate-cv',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCandidateDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 3,
        );
      },
    ),
    GoRoute(
      path: '/candidate/:uid/cover-letter',
      name: 'candidate-cover-letter',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCandidateDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 4,
        );
      },
    ),
    GoRoute(
      path: '/candidate/:uid/video-cv',
      name: 'candidate-video-cv',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCandidateDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 5,
        );
      },
    ),
    GoRoute(
      path: '/candidate/:uid/privacy',
      name: 'candidate-privacy-portal',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        final cubit = DataRequestsCubit(
          repository: context.read<DataRequestRepository>(),
        );
        return BlocProvider(
          create: (_) => cubit,
          child: CandidatePrivacyPortalScreen(candidateUid: uid),
        );
      },
    ),
  ];
}

Widget _buildCandidateDashboardRoute({
  required BuildContext context,
  required String uid,
  required int initialIndex,
}) {
  final applicationsCubit = MyApplicationsCubit(
    applicationService: context.read<ApplicationService>(),
    candidateAuthCubit: context.read<CandidateAuthCubit>(),
    firebaseAuth: context.read<FirebaseAuth>(),
  )..start();

  final interviewsCubit = InterviewListCubit(
    repository: context.read<InterviewRepository>(),
    uid: uid,
  )..start();

  final curriculumCubit = context.read<CurriculumCubit>();
  final curriculumFormCubit = CurriculumFormCubit(
    curriculumCubit: curriculumCubit,
    analysisService: context.read<CvAnalysisService>(),
  );

  final calendarCubit = CalendarCubit(context.read<CalendarRepository>())
    ..loadMonth(DateTime.now());

  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => applicationsCubit),
      BlocProvider(create: (_) => interviewsCubit),
      BlocProvider(create: (_) => curriculumFormCubit),
      BlocProvider(create: (_) => calendarCubit),
    ],
    child: CandidateDashboardScreen(
      uid: uid,
      initialIndex: initialIndex,
      applicationsCubit: applicationsCubit,
      interviewsCubit: interviewsCubit,
      curriculumFormCubit: curriculumFormCubit,
      calendarCubit: calendarCubit,
      profileCubit: context.read<ProfileCubit>(),
    ),
  );
}
