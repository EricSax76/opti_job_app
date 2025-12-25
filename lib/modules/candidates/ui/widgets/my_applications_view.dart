import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/aplications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/aplications/ui/application_status.dart';

class MyApplicationsView extends StatelessWidget {
  const MyApplicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyApplicationsCubit, MyApplicationsState>(
      builder: (context, state) {
        if (state.status == ApplicationsStatus.loading ||
            state.status == ApplicationsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ApplicationsStatus.error) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Error al cargar tus postulaciones.',
            ),
          );
        }

        if (state.applications.isEmpty) {
          return const Center(
            child: Text('Aún no te has postulado a ninguna oferta.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<MyApplicationsCubit>().loadMyApplications(),
          child: _ApplicationsList(applications: state.applications),
        );
      },
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  const _ApplicationsList({required this.applications});

  final List<CandidateApplicationEntry> applications;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final entry = applications[index];
        final offer = entry.offer;
        final fallbackTitle = entry.application.jobOfferTitle;
        final title =
            offer?.title ??
            ((fallbackTitle != null && fallbackTitle.trim().isNotEmpty)
                ? fallbackTitle
                : 'Oferta');
        final description = offer?.description ?? '';
        final statusChip = applicationStatusChip(entry.application.status);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(title),
            subtitle: Text(
              [
                'Estado: ${applicationStatusLabel(entry.application.status)}',
                if (description.isNotEmpty) description,
              ].join('\n'),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                statusChip,
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap:
                offer == null ? null : () => context.go('/job-offer/${offer.id}'),
          ),
        );
      },
    );
  }
}
