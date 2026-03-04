import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/core/theme/theme_cubit.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_dashboard_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_dashboard_screen.dart';
import 'package:opti_job_app/modules/interviews/cubits/interview_list_cubit.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';

import '../support/test_cubits.dart';

class _MockInterviewRepository extends Mock implements InterviewRepository {}

void main() {
  testWidgets('shows unauthenticated message when no company is in session', (
    tester,
  ) async {
    final authCubit = TestCompanyAuthCubit(const CompanyAuthState());

    await tester.pumpWidget(
      _wrap(
        authCubit: authCubit,
        offersCubit: TestCompanyJobOffersCubit(
          const CompanyJobOffersState(status: CompanyJobOffersStatus.success),
        ),
        formCubit: TestJobOfferFormCubit(const JobOfferFormState()),
      ),
    );

    expect(find.text('Acceso requerido'), findsOneWidget);
  });

  testWidgets('loads offers when authenticated company is available', (
    tester,
  ) async {
    final authCubit = TestCompanyAuthCubit(
      const CompanyAuthState(
        status: AuthStatus.authenticated,
        company: Company(
          id: 1,
          name: 'Acme',
          email: 'acme@example.com',
          uid: 'company-1',
        ),
      ),
    );
    final offersCubit = TestCompanyJobOffersCubit(
      const CompanyJobOffersState(status: CompanyJobOffersStatus.success),
    );

    await tester.pumpWidget(
      _wrap(
        authCubit: authCubit,
        offersCubit: offersCubit,
        formCubit: TestJobOfferFormCubit(const JobOfferFormState()),
      ),
    );

    expect(offersCubit.loadedCompanyUids, ['company-1']);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Publicar oferta'), findsOneWidget);
    expect(find.text('Mis ofertas'), findsOneWidget);
  });

  testWidgets('shows success snackbar when offer publish succeeds', (
    tester,
  ) async {
    final authCubit = TestCompanyAuthCubit(
      const CompanyAuthState(
        status: AuthStatus.authenticated,
        company: Company(
          id: 1,
          name: 'Acme',
          email: 'acme@example.com',
          uid: 'company-1',
        ),
      ),
    );
    final offersCubit = TestCompanyJobOffersCubit(
      const CompanyJobOffersState(status: CompanyJobOffersStatus.success),
    );
    final formCubit = TestJobOfferFormCubit(const JobOfferFormState());

    await tester.pumpWidget(
      _wrap(
        authCubit: authCubit,
        offersCubit: offersCubit,
        formCubit: formCubit,
      ),
    );

    formCubit.emitState(
      const JobOfferFormState(status: JobOfferFormStatus.success),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oferta publicada con éxito.'), findsOneWidget);
  });

  testWidgets('shows error snackbar when offer publish fails', (tester) async {
    final authCubit = TestCompanyAuthCubit(
      const CompanyAuthState(
        status: AuthStatus.authenticated,
        company: Company(
          id: 1,
          name: 'Acme',
          email: 'acme@example.com',
          uid: 'company-1',
        ),
      ),
    );
    final offersCubit = TestCompanyJobOffersCubit(
      const CompanyJobOffersState(status: CompanyJobOffersStatus.success),
    );
    final formCubit = TestJobOfferFormCubit(const JobOfferFormState());

    await tester.pumpWidget(
      _wrap(
        authCubit: authCubit,
        offersCubit: offersCubit,
        formCubit: formCubit,
      ),
    );

    formCubit.emitState(
      const JobOfferFormState(status: JobOfferFormStatus.failure),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Error al publicar la oferta. Intenta nuevamente.'),
      findsOneWidget,
    );
  });
}

Widget _wrap({
  required TestCompanyAuthCubit authCubit,
  required TestCompanyJobOffersCubit offersCubit,
  required TestJobOfferFormCubit formCubit,
}) {
  final dashboardCubit = CompanyDashboardCubit(
    companyJobOffersCubit: offersCubit,
    companyUid: 'company-1',
    initialIndex: 0,
  );
  final offerCreationCubit = TestCompanyOfferCreationCubit(
    const CompanyOfferCreationState(),
  );
  final interviewsCubit = TestInterviewListCubit(InterviewListInitial());
  final interviewRepository = _MockInterviewRepository();

  return MultiBlocProvider(
    providers: [
      RepositoryProvider<InterviewRepository>.value(
        value: interviewRepository,
      ),
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<CompanyAuthCubit>.value(value: authCubit),
      BlocProvider<CompanyJobOffersCubit>.value(value: offersCubit),
      BlocProvider<JobOfferFormCubit>.value(value: formCubit),
      BlocProvider<OfferApplicantsCubit>(
        create: (_) => TestOfferApplicantsCubit(const OfferApplicantsState()),
      ),
      BlocProvider<CompanyDashboardCubit>(create: (_) => dashboardCubit),
      BlocProvider<CompanyOfferCreationCubit>(
        create: (_) => offerCreationCubit,
      ),
      BlocProvider<InterviewListCubit>(create: (_) => interviewsCubit),
    ],
    child: MaterialApp(
      home: CompanyDashboardScreen(
        dashboardCubit: dashboardCubit,
        offerCreationCubit: offerCreationCubit,
        interviewsCubit: interviewsCubit,
      ),
    ),
  );
}
