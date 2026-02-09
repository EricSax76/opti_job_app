import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_offer_creation_tab.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';

import '../support/test_cubits.dart';

void main() {
  testWidgets('renders company header and submit action', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('Hola, Acme Corp'), findsOneWidget);
    expect(find.text('Publicar oferta'), findsOneWidget);
  });

  testWidgets('submits payload with required fields', (tester) async {
    final formCubit = TestJobOfferFormCubit(const JobOfferFormState());
    await tester.pumpWidget(_wrap(formCubit: formCubit));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Backend Engineer',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'API development');
    await tester.enterText(find.byType(TextFormField).at(2), 'Madrid');

    final publishButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Publicar oferta'),
    );
    publishButton.onPressed?.call();
    await tester.pump();

    expect(formCubit.submittedPayloads, hasLength(1));
    final payload = formCubit.submittedPayloads.first;
    expect(payload.title, 'Backend Engineer');
    expect(payload.description, 'API development');
    expect(payload.location, 'Madrid');
    expect(payload.companyUid, 'company-1');
    expect(payload.companyName, 'Acme Corp');
  });

  testWidgets('resets form when submit state changes to success', (
    tester,
  ) async {
    final formCubit = TestJobOfferFormCubit(const JobOfferFormState());
    await tester.pumpWidget(_wrap(formCubit: formCubit));

    await tester.enterText(find.byType(TextFormField).at(0), 'Data Engineer');
    await tester.enterText(find.byType(TextFormField).at(1), 'Data platform');
    await tester.enterText(find.byType(TextFormField).at(2), 'Barcelona');
    expect(find.text('Data Engineer'), findsOneWidget);

    formCubit.emitState(
      const JobOfferFormState(status: JobOfferFormStatus.success),
    );
    await tester.pump();

    expect(find.text('Data Engineer'), findsNothing);
    expect(find.text('Data platform'), findsNothing);
    expect(find.text('Barcelona'), findsNothing);
  });
}

Widget _wrap({TestJobOfferFormCubit? formCubit}) {
  final authCubit = TestCompanyAuthCubit(
    const CompanyAuthState(
      status: AuthStatus.authenticated,
      company: Company(
        id: 1,
        name: 'Acme Corp',
        email: 'acme@example.com',
        uid: 'company-1',
      ),
    ),
  );
  final resolvedFormCubit =
      formCubit ?? TestJobOfferFormCubit(const JobOfferFormState());

  return MultiBlocProvider(
    providers: [
      BlocProvider<CompanyAuthCubit>.value(value: authCubit),
      BlocProvider<JobOfferFormCubit>.value(value: resolvedFormCubit),
    ],
    child: const MaterialApp(home: Scaffold(body: CompanyOfferCreationTab())),
  );
}
