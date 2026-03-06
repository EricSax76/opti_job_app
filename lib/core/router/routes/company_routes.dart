import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/analytics/cubits/analytics_dashboard_cubit.dart';
import 'package:opti_job_app/modules/analytics/repositories/analytics_repository.dart';
import 'package:opti_job_app/modules/analytics/ui/pages/analytics_dashboard_screen.dart';
import 'package:opti_job_app/modules/applicants/cubits/applicant_curriculum_cubit.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/applicants/ui/pages/applicant_curriculum_screen.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_template_cubit.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_dashboard_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_profile_form_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_dashboard_screen.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_profile_screen.dart';
import 'package:opti_job_app/modules/compliance/ui/pages/consent_management_screen.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_pdf_service.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum_share_service.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

List<RouteBase> buildCompanyRoutes() {
  return [
    GoRoute(
      path: '/DashboardCompany',
      name: 'company-dashboard-legacy',
      builder: (context, state) {
        final uid = context.read<CompanyAuthCubit>().state.company?.uid ?? '';
        return _buildCompanyDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 0,
        );
      },
    ),
    GoRoute(
      path: '/company/:uid/dashboard',
      name: 'company-dashboard',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCompanyDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 0,
        );
      },
    ),
    GoRoute(
      path: '/company/:uid/publish-offer',
      name: 'company-publish-offer',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCompanyDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 1,
        );
      },
    ),
    GoRoute(
      path: '/company/:uid/offers',
      name: 'company-offers',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCompanyDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 2,
        );
      },
    ),
    GoRoute(
      path: '/company/:uid/candidates',
      name: 'company-candidates',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCompanyDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 3,
        );
      },
    ),
    GoRoute(
      path: '/company/:uid/interviews',
      name: 'company-interviews',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return _buildCompanyDashboardRoute(
          context: context,
          uid: uid,
          initialIndex: 4,
        );
      },
    ),
    GoRoute(
      path: '/company/profile',
      name: 'company-profile',
      builder: (context, state) {
        final cubit = CompanyProfileFormCubit(
          profileRepository: context.read<ProfileRepository>(),
          companyAuthCubit: context.read<CompanyAuthCubit>(),
        );
        return BlocProvider(
          create: (_) => cubit,
          child: CompanyProfileScreen(cubit: cubit),
        );
      },
    ),
    GoRoute(
      path: '/company/:uid/consents',
      name: 'company-consents',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return ConsentManagementScreen(companyId: uid);
      },
    ),
    GoRoute(
      path: '/company/:uid/analytics',
      name: 'company-analytics',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        final cubit = AnalyticsDashboardCubit(
          repository: context.read<AnalyticsRepository>(),
        );
        return BlocProvider(
          create: (_) => cubit,
          child: AnalyticsDashboardScreen(companyId: uid),
        );
      },
    ),
    GoRoute(
      path: '/company/offers/:offerId/applicants/:candidateUid/cv',
      name: 'company-applicant-cv',
      builder: (context, state) {
        final uid = state.pathParameters['candidateUid'] ?? '';
        final offerId = state.pathParameters['offerId'] ?? '';

        final cubit = ApplicantCurriculumCubit(
          profileRepository: context.read<ProfileRepository>(),
          curriculumRepository: context.read<CurriculumRepository>(),
          jobOfferRepository: context.read<JobOfferRepository>(),
          aiRepository: context.read<AiRepository>(),
          curriculumPdfService: CurriculumPdfService(),
          curriculumShareService: CurriculumShareService(),
        )..start(candidateUid: uid, offerId: offerId);

        return BlocProvider(
          create: (_) => cubit,
          child: ApplicantCurriculumScreen(
            cubit: cubit,
            candidateUid: uid,
            offerId: offerId,
          ),
        );
      },
    ),
  ];
}

Widget _buildCompanyDashboardRoute({
  required BuildContext context,
  required String uid,
  required int initialIndex,
}) {
  final companyJobOffersCubit = CompanyJobOffersCubit(
    context.read<JobOfferRepository>(),
  );

  final jobOfferFormCubit = JobOfferFormCubit(
    context.read<JobOfferRepository>(),
    context.read<AiService>(),
  );

  final offerApplicantsCubit = OfferApplicantsCubit(
    context.read<ApplicantsRepository>(),
  );

  final companyDashboardCubit = CompanyDashboardCubit(
    companyJobOffersCubit: companyJobOffersCubit,
    companyUid: uid,
    initialIndex: initialIndex,
  );

  final companyOfferCreationCubit = CompanyOfferCreationCubit(
    aiRepository: context.read<AiRepository>(),
  );

  final interviewListCubit = InterviewListCubit(
    repository: context.read<InterviewRepository>(),
    uid: uid,
  )..start();

  final pipelineTemplateCubit = PipelineTemplateCubit(
    pipelineRepository: context.read<PipelineRepository>(),
  )..loadPipelines(uid);

  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => companyJobOffersCubit),
      BlocProvider(create: (_) => jobOfferFormCubit),
      BlocProvider(create: (_) => offerApplicantsCubit),
      BlocProvider(create: (_) => companyDashboardCubit),
      BlocProvider(create: (_) => companyOfferCreationCubit),
      BlocProvider(create: (_) => interviewListCubit),
      BlocProvider(create: (_) => pipelineTemplateCubit),
    ],
    child: CompanyDashboardScreen(
      dashboardCubit: companyDashboardCubit,
      offerCreationCubit: companyOfferCreationCubit,
      interviewsCubit: interviewListCubit,
    ),
  );
}
