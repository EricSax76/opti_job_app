import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard/dashboard_calendar_panel.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard/dashboard_filters_sidebar.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/dashboard/dashboard_offers_section.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_cubit.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCandidateName = context.select<ProfileCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final authCandidateName = context.select<CandidateAuthCubit, String?>(
      (cubit) => cubit.state.candidate?.name,
    );
    final candidateName =
        profileCandidateName ?? authCandidateName ?? 'Candidato';

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 600;

        return Row(
          children: [
            if (showSidebar) const DashboardFiltersSidebar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $candidateName',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Aquí tienes ofertas seleccionadas para ti.'),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: DashboardOffersSection(
                              showTwoColumns: showSidebar,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const DashboardCalendarPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
