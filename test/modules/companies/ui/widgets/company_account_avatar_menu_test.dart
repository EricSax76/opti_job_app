import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/auth/cubits/auth_status.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';

import '../support/test_cubits.dart';

void main() {
  testWidgets('navigates to declared profile route from popup menu', (
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

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: CompanyAccountAvatarMenu()),
        ),
        GoRoute(
          path: '/company/profile',
          name: 'company-profile',
          builder: (_, _) => const Scaffold(body: Text('Perfil Route')),
        ),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<CompanyAuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil Route'), findsOneWidget);
  });
}
