import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/offers/company_offers_section.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/offer_card.dart';

import '../support/test_cubits.dart';

void main() {
  testWidgets('shows loading indicator when offers are loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithProviders(
        offersState: const CompanyJobOffersState(
          status: CompanyJobOffersStatus.loading,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows failure message when offers request fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithProviders(
        offersState: const CompanyJobOffersState(
          status: CompanyJobOffersStatus.failure,
          errorMessage: 'Fallo de prueba',
        ),
      ),
    );

    expect(find.text('Fallo de prueba'), findsOneWidget);
  });

  testWidgets('renders offers list in success state', (tester) async {
    await tester.pumpWidget(
      _wrapWithProviders(
        offersState: CompanyJobOffersState(
          status: CompanyJobOffersStatus.success,
          offers: const [
            JobOffer(
              id: 'offer-1',
              title: 'Backend Engineer',
              description: 'Desc',
              location: 'Madrid',
              companyUid: 'company-1',
            ),
            JobOffer(
              id: 'offer-2',
              title: 'Mobile Engineer',
              description: 'Desc',
              location: 'Barcelona',
              companyUid: 'company-1',
            ),
          ],
        ),
      ),
    );

    expect(find.byType(OfferCard), findsNWidgets(2));
    expect(find.text('Backend Engineer'), findsOneWidget);
    expect(find.text('Mobile Engineer'), findsOneWidget);
  });
}

Widget _wrapWithProviders({required CompanyJobOffersState offersState}) {
  final companyAuthCubit = TestCompanyAuthCubit(
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
  final offersCubit = TestCompanyJobOffersCubit(offersState);
  final applicantsCubit = TestOfferApplicantsCubit(
    const OfferApplicantsState(),
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider<CompanyAuthCubit>.value(value: companyAuthCubit),
      BlocProvider<CompanyJobOffersCubit>.value(value: offersCubit),
      BlocProvider<OfferApplicantsCubit>.value(value: applicantsCubit),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: CompanyOffersSection(),
            ),
          ],
        ),
      ),
    ),
  );
}
