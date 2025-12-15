import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/auth/cubit/auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart'
    show CandidateAuthCubit;
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart'
    show CompanyAuthCubit;
import 'package:opti_job_app/features/profiles/cubit/profile_cubit.dart';
import 'package:opti_job_app/core/shared/widgets/app_nav_bar.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final profileState = context.watch<ProfileCubit>().state;

    final name = authState.isCandidate
        ? profileState.candidate?.name ?? 'Candidato'
        : profileState.company?.name ?? 'Empresa';

    return Scaffold(
      appBar: const AppNavBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $name 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bienvenido a tu espacio personalizado. Antes de continuar, revisa tu perfil y completa los datos clave.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      if (authState.isCandidate) {
                        context.read<CandidateAuthCubit>().completeOnboarding();
                        context.go('/CandidateDashboard');
                      } else {
                        context.read<CompanyAuthCubit>().completeOnboarding();
                        context.go('/DashboardCompany');
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
