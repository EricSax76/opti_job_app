import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_offer_creation_tab.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_form_cubit.dart';

import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_offer_creation_state.dart';

import '../support/test_cubits.dart';

class _MockAiRepository extends Mock implements AiRepository {}

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

    // Select required dropdown values.
    await _selectDropdown(tester, 'Modalidad', 'Presencial');
    await _selectDropdown(tester, 'Categoría del puesto',
        'Informática y telecomunicaciones');
    await _selectDropdown(tester, 'Estudios mínimos', 'Grado');
    await _selectDropdown(tester, 'Jornada laboral', 'Completa');
    await _selectDropdown(tester, 'Tipo de contrato', 'Indefinido');

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
    expect(payload.jobType, 'Presencial');
    expect(payload.jobCategory, 'Informática y telecomunicaciones');
    expect(payload.education, 'Grado');
    expect(payload.workSchedule, 'Completa');
    expect(payload.contractType, 'Indefinido');
  });

  testWidgets('does not submit when required fields contain only spaces', (
    tester,
  ) async {
    final formCubit = TestJobOfferFormCubit(const JobOfferFormState());
    await tester.pumpWidget(_wrap(formCubit: formCubit));

    await tester.enterText(find.byType(TextFormField).at(0), '   ');
    await tester.enterText(find.byType(TextFormField).at(1), '   ');
    await tester.enterText(find.byType(TextFormField).at(2), '   ');

    final publishButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Publicar oferta'),
    );
    publishButton.onPressed?.call();
    await tester.pump();

    expect(formCubit.submittedPayloads, isEmpty);
    expect(find.text('El título es obligatorio'), findsOneWidget);
    expect(find.text('La descripción es obligatoria'), findsOneWidget);
    expect(find.text('La ubicación es obligatoria'), findsOneWidget);
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

/// Selects a value from a [DropdownButtonFormField] by tapping on the dropdown
/// whose label matches [label] and then tapping on the menu item [value].
Future<void> _selectDropdown(
  WidgetTester tester,
  String label,
  String value,
) async {
  // Find the dropdown by its label text.
  final dropdownFinder = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<String> &&
        widget.decoration.labelText == label,
  );

  // Scroll into view before tapping (some fields are below the viewport).
  await tester.ensureVisible(dropdownFinder);
  await tester.pumpAndSettle();
  await tester.tap(dropdownFinder);
  await tester.pumpAndSettle();

  // Tap the matching menu item — .last handles overlay duplicates.
  final itemFinder = find.text(value).last;
  await tester.ensureVisible(itemFinder);
  await tester.pumpAndSettle();
  await tester.tap(itemFinder);
  await tester.pumpAndSettle();
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
  final aiRepository = _MockAiRepository();
  final offerCreationCubit = TestCompanyOfferCreationCubit(
    const CompanyOfferCreationState(),
  );

  return MultiBlocProvider(
    providers: [
      RepositoryProvider<AiRepository>.value(value: aiRepository),
      BlocProvider<CompanyAuthCubit>.value(value: authCubit),
      BlocProvider<JobOfferFormCubit>.value(value: resolvedFormCubit),
      BlocProvider<CompanyOfferCreationCubit>.value(value: offerCreationCubit),
    ],
    child: const MaterialApp(home: Scaffold(body: CompanyOfferCreationTab())),
  );
}
