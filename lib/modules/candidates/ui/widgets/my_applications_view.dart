import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/applications/ui/application_status.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/modern_application_card.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no te has postulado a ninguna oferta.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              context.read<MyApplicationsCubit>().loadMyApplications(),
          child: ApplicationsList(applications: state.applications),
        );
      },
    );
  }
}

class ApplicationsList extends StatelessWidget {
  const ApplicationsList({super.key, required this.applications});

  final List<CandidateApplicationEntry> applications;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 1;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 190,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            return _buildApplicationCard(context, applications[index]);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    CandidateApplicationEntry entry,
  ) {
    final offer = entry.offer;
    final fallbackTitle = entry.application.jobOfferTitle;
    final title =
        offer?.title ??
        ((fallbackTitle != null && fallbackTitle.trim().isNotEmpty)
            ? fallbackTitle
            : 'Oferta');
    final statusChip = applicationStatusChip(entry.application.status);
    final company = offer?.companyName ?? 'Empresa no especificada';
    final salary = offer == null ? null : _formatSalary(offer);
    final location = offer?.location;
    final modality = offer == null
        ? null
        : (offer.jobType ?? 'Modalidad no especificada');

    return ModernApplicationCard(
      title: title,
      company: company,
      avatarUrl: offer?.companyAvatarUrl,
      salary: salary,
      location: location,
      modality: modality,
      statusBadge: statusChip,
      onTap: offer == null
          ? null
          : () => context.push('/job-offer/${offer.id}'),
    );
  }
}

String? _formatSalary(JobOffer offer) {
  final min = offer.salaryMin?.trim();
  final max = offer.salaryMax?.trim();

  final hasMin = min != null && min.isNotEmpty;
  final hasMax = max != null && max.isNotEmpty;

  if (hasMin && hasMax) return '$min - $max';
  if (hasMin) return 'Desde $min';
  if (hasMax) return 'Hasta $max';
  return null;
}
