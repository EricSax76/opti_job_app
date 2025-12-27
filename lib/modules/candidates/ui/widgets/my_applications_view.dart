import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/modules/aplications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/aplications/ui/application_status.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_summary_card.dart';

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
    const background = Color(0xFFF8FAFC);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
        final statusChip = applicationStatusChip(entry.application.status);
        final company = offer?.companyName ?? 'Empresa no especificada';
        final salary = offer == null ? null : _formatSalary(offer);
        final modality =
            offer == null ? null : (offer.jobType ?? 'Modalidad no especificada');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: background),
            child: JobOfferSummaryCard(
              title: title,
              company: company,
              salary: salary,
              modality: modality,
              trailing: statusChip,
              onTap:
                  offer == null
                      ? null
                      : () => context.go('/job-offer/${offer.id}'),
            ),
          ),
        );
      },
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
