import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/dashboard_offers_card.dart';

import '../support/test_cubits.dart';

void main() {
  testWidgets('shows failure message and retries loading company offers', (
    tester,
  ) async {
    var loadCandidatesPressed = false;
    final authCubit = _buildCompanyAuthCubit();
    final offersCubit = TestCompanyJobOffersCubit(
      const CompanyJobOffersState(
        status: CompanyJobOffersStatus.failure,
        errorMessage: 'No se pudieron cargar tus ofertas.',
      ),
    );

    await tester.pumpWidget(
      _wrap(
        authCubit: authCubit,
        offersCubit: offersCubit,
        onLoadCandidates: () => loadCandidatesPressed = true,
      ),
    );

    expect(find.text('No se pudieron cargar tus ofertas.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(offersCubit.loadedCompanyUids, ['company-1']);
    expect(loadCandidatesPressed, isFalse);
  });

  testWidgets('keeps candidates refresh action in success state', (
    tester,
  ) async {
    var loadCandidatesPressed = false;
    final authCubit = _buildCompanyAuthCubit();
    final offersCubit = TestCompanyJobOffersCubit(
      CompanyJobOffersState(
        status: CompanyJobOffersStatus.success,
        offers: const [
          JobOffer(
            id: 'offer-1',
            title: 'Backend Engineer',
            description: 'Desc',
            location: 'Madrid',
            companyUid: 'company-1',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _wrap(
        authCubit: authCubit,
        offersCubit: offersCubit,
        onLoadCandidates: () => loadCandidatesPressed = true,
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Actualizar candidatos'), findsOneWidget);

    await tester.tap(find.text('Actualizar candidatos'));
    await tester.pump();

    expect(loadCandidatesPressed, isTrue);
  });
}

TestCompanyAuthCubit _buildCompanyAuthCubit() {
  return TestCompanyAuthCubit(
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
}

Widget _wrap({
  required TestCompanyAuthCubit authCubit,
  required TestCompanyJobOffersCubit offersCubit,
  required VoidCallback onLoadCandidates,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<CompanyAuthCubit>.value(value: authCubit),
      BlocProvider<CompanyJobOffersCubit>.value(value: offersCubit),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: DashboardOffersCard(onLoadCandidates: onLoadCandidates),
      ),
    ),
  );
}
