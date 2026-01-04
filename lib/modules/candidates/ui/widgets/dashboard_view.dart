import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/features/calendar/cubit/calendar_cubit.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_summary_card.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_cubit.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/calendar_panel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;
    final profileState = context.watch<ProfileCubit>().state;
    final offersState = context.watch<JobOffersCubit>().state;
    final calendarState = context.watch<CalendarCubit>().state;

    final candidateName =
        profileState.candidate?.name ??
        authState.candidate?.name ??
        'Candidato';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $candidateName',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Aquí tienes ofertas seleccionadas para ti.'),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _OffersList(state: offersState)),
                const SizedBox(height: 16),
                CalendarPanel(state: calendarState),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersList extends StatelessWidget {
  const _OffersList({required this.state});

  final JobOffersState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == JobOffersStatus.loading ||
        state.status == JobOffersStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == JobOffersStatus.failure) {
      return Center(
        child: Text(state.errorMessage ?? 'Error al cargar las ofertas.'),
      );
    }

    if (state.offers.isEmpty) {
      return const Center(
        child: Text('Aún no hay ofertas disponibles. Intenta más tarde.'),
      );
    }

    return ListView.builder(
      itemCount: state.offers.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final offer = state.offers[index];
        final company =
            offer.companyId == null ? null : state.companiesById[offer.companyId!];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: JobOfferSummaryCard(
            title: offer.title,
            company: offer.companyName ?? company?.name ?? 'Empresa no especificada',
            avatarUrl: offer.companyAvatarUrl ?? company?.avatarUrl,
            salary: _formatSalary(offer),
            modality: offer.jobType ?? 'Modalidad no especificada',
            onTap: () => context.push('/job-offer/${offer.id}'),
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
