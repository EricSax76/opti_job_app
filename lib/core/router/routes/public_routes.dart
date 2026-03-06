import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/ui/pages/candidate_login_screen.dart';
import 'package:opti_job_app/auth/ui/pages/candidate_register_screen.dart';
import 'package:opti_job_app/auth/ui/pages/company_login_screen.dart';
import 'package:opti_job_app/auth/ui/pages/company_register_screen.dart';
import 'package:opti_job_app/features/onboarding/view/pages/onboarding_screen.dart';
import 'package:opti_job_app/home/pages/landing_screen.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_session_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/interviews/ui/pages/interview_chat_page.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_detail_screen.dart';
import 'package:opti_job_app/modules/job_offers/ui/pages/job_offer_list_screen.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

List<RouteBase> buildPublicRoutes({required String authBootstrapPath}) {
  return [
    GoRoute(
      path: authBootstrapPath,
      name: 'auth-bootstrap',
      builder: (context, state) => const AuthBootstrapScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'landing',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/job-offer',
      name: 'job-offers',
      builder: (context, state) {
        final cubit = JobOffersCubit(
          context.read<JobOfferRepository>(),
          profileRepository: context.read<ProfileRepository>(),
        );
        return BlocProvider(
          create: (_) => cubit,
          child: JobOfferListScreen(cubit: cubit),
        );
      },
    ),
    GoRoute(
      path: '/job-offer/:id',
      name: 'job-offer-detail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final sourceChannel = state.uri.queryParameters['source'];
        final candidateUid = context
            .read<CandidateAuthCubit>()
            .state
            .candidate
            ?.uid;

        final cubit = JobOfferDetailCubit(
          context.read<JobOfferRepository>(),
          context.read<ApplicationService>(),
          curriculumRepository: context.read<CurriculumRepository>(),
          aiRepository: context.read<AiRepository>(),
          profileRepository: context.read<ProfileRepository>(),
          sourceChannel: sourceChannel,
        )..start(id, candidateUid: candidateUid);

        return BlocProvider(
          create: (_) => cubit,
          child: JobOfferDetailScreen(offerId: id, cubit: cubit),
        );
      },
    ),
    GoRoute(
      path: '/CandidateLogin',
      name: 'candidate-login',
      builder: (context, state) => const CandidateLoginScreen(),
    ),
    GoRoute(
      path: '/candidateregister',
      name: 'candidate-register',
      builder: (context, state) => const CandidateRegisterScreen(),
    ),
    GoRoute(
      path: '/CompanyLogin',
      name: 'company-login',
      builder: (context, state) => const CompanyLoginScreen(),
    ),
    GoRoute(
      path: '/companyregister',
      name: 'company-register',
      builder: (context, state) => const CompanyRegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    // shell-ex-001 (Fase 6.5): approved exception for immersive interview chat.
    // Source of truth: docs/fase_6_5_registro_excepciones_shell_core.md
    GoRoute(
      path: '/interviews/:id',
      name: 'interview-chat',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final cubit =
            InterviewSessionCubit(
                repository: context.read<InterviewRepository>(),
                interviewId: id,
              )
              ..start()
              ..markAsSeen();

        // Wrap in BlocProvider to ensure it gets closed when the route is popped
        return BlocProvider(
          create: (_) => cubit,
          child: InterviewChatPage(cubit: cubit),
        );
      },
    ),
  ];
}

class AuthBootstrapScreen extends StatelessWidget {
  const AuthBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
