import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_profile_form_cubit.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/models/company_compliance_profile.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';
import 'package:opti_job_app/modules/companies/ui/pages/company_profile_screen.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

import '../support/test_cubits.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const CompanyMultipostingSettings());
    registerFallbackValue(const CompanyComplianceProfile());
  });

  testWidgets('shows sign-in message when there is no authenticated company', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        authCubit: TestCompanyAuthCubit(const CompanyAuthState()),
        profileRepository: _MockProfileRepository(),
      ),
    );

    expect(find.text('Inicia sesión para ver tu perfil.'), findsOneWidget);
  });

  testWidgets('shows loading and success feedback when profile is saved', (
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
    final profileRepository = _MockProfileRepository();
    final completer = Completer<Company>();
    when(
      () => profileRepository.updateCompanyProfile(
        uid: 'company-1',
        name: 'Acme Labs',
        website: any(named: 'website'),
        industry: any(named: 'industry'),
        teamSize: any(named: 'teamSize'),
        headquarters: any(named: 'headquarters'),
        description: any(named: 'description'),
        multipostingSettings: any(named: 'multipostingSettings'),
        complianceProfile: any(named: 'complianceProfile'),
        avatarBytes: null,
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      _wrap(authCubit: authCubit, profileRepository: profileRepository),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Acme Labs');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();

    verify(
      () => profileRepository.updateCompanyProfile(
        uid: 'company-1',
        name: 'Acme Labs',
        website: any(named: 'website'),
        industry: any(named: 'industry'),
        teamSize: any(named: 'teamSize'),
        headquarters: any(named: 'headquarters'),
        description: any(named: 'description'),
        multipostingSettings: any(named: 'multipostingSettings'),
        complianceProfile: any(named: 'complianceProfile'),
        avatarBytes: null,
      ),
    ).called(1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const Company(
        id: 1,
        name: 'Acme Labs',
        email: 'acme@example.com',
        uid: 'company-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perfil actualizado.'), findsOneWidget);
    expect(authCubit.updatedCompanies.last.name, 'Acme Labs');
  });

  testWidgets('shows error feedback when profile save fails', (tester) async {
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
    final profileRepository = _MockProfileRepository();
    when(
      () => profileRepository.updateCompanyProfile(
        uid: 'company-1',
        name: 'Acme Labs',
        website: any(named: 'website'),
        industry: any(named: 'industry'),
        teamSize: any(named: 'teamSize'),
        headquarters: any(named: 'headquarters'),
        description: any(named: 'description'),
        multipostingSettings: any(named: 'multipostingSettings'),
        complianceProfile: any(named: 'complianceProfile'),
        avatarBytes: null,
      ),
    ).thenThrow(Exception('save failed'));

    await tester.pumpWidget(
      _wrap(authCubit: authCubit, profileRepository: profileRepository),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Acme Labs');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    verify(
      () => profileRepository.updateCompanyProfile(
        uid: 'company-1',
        name: 'Acme Labs',
        website: any(named: 'website'),
        industry: any(named: 'industry'),
        teamSize: any(named: 'teamSize'),
        headquarters: any(named: 'headquarters'),
        description: any(named: 'description'),
        multipostingSettings: any(named: 'multipostingSettings'),
        complianceProfile: any(named: 'complianceProfile'),
        avatarBytes: null,
      ),
    ).called(1);
    expect(find.text('No se pudo actualizar el perfil.'), findsOneWidget);
  });

  testWidgets('allows saving company profile with no multiposting channels', (
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
    final profileRepository = _MockProfileRepository();
    when(
      () => profileRepository.updateCompanyProfile(
        uid: 'company-1',
        name: 'Acme Labs',
        website: any(named: 'website'),
        industry: any(named: 'industry'),
        teamSize: any(named: 'teamSize'),
        headquarters: any(named: 'headquarters'),
        description: any(named: 'description'),
        multipostingSettings: any(named: 'multipostingSettings'),
        complianceProfile: any(named: 'complianceProfile'),
        avatarBytes: null,
      ),
    ).thenAnswer(
      (_) async => const Company(
        id: 1,
        name: 'Acme Labs',
        email: 'acme@example.com',
        uid: 'company-1',
        multipostingSettings: CompanyMultipostingSettings(enabledChannels: []),
      ),
    );

    await tester.pumpWidget(
      _wrap(authCubit: authCubit, profileRepository: profileRepository),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Acme Labs');
    await tester.pump();

    await tester.ensureVisible(find.text('LinkedIn'));
    await tester.tap(find.text('LinkedIn'));
    await tester.pump();
    await tester.ensureVisible(find.text('Indeed'));
    await tester.tap(find.text('Indeed'));
    await tester.pump();
    await tester.ensureVisible(find.text('Portal universitario'));
    await tester.tap(find.text('Portal universitario'));
    await tester.pump();

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final captured = verify(
      () => profileRepository.updateCompanyProfile(
        uid: 'company-1',
        name: 'Acme Labs',
        website: any(named: 'website'),
        industry: any(named: 'industry'),
        teamSize: any(named: 'teamSize'),
        headquarters: any(named: 'headquarters'),
        description: any(named: 'description'),
        multipostingSettings: captureAny(named: 'multipostingSettings'),
        complianceProfile: any(named: 'complianceProfile'),
        avatarBytes: null,
      ),
    ).captured;
    final settings = captured.first as CompanyMultipostingSettings;
    expect(settings.enabledChannels, isEmpty);
  });
}

Widget _wrap({
  required TestCompanyAuthCubit authCubit,
  required ProfileRepository profileRepository,
}) {
  return MultiBlocProvider(
    providers: [BlocProvider<CompanyAuthCubit>.value(value: authCubit)],
    child: BlocProvider<CompanyProfileFormCubit>(
      create: (_) => CompanyProfileFormCubit(
        profileRepository: profileRepository,
        companyAuthCubit: authCubit,
      ),
      child: Builder(
        builder: (context) => MaterialApp(
          home: CompanyProfileScreen(
            cubit: context.read<CompanyProfileFormCubit>(),
          ),
        ),
      ),
    ),
  );
}
