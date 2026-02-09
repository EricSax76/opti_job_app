import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/applications/ui/application_status.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/modern_application_card.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';

class InterviewsView extends StatelessWidget {
  const InterviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyApplicationsCubit, MyApplicationsState>(
      builder: (context, state) {
        if (state.status == ApplicationsStatus.loading ||
            state.status == ApplicationsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ApplicationsStatus.error) {
          return StateMessage(
            title: 'No se pudieron cargar tus entrevistas',
            message:
                state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
          );
        }

        final interviews = state.applications
            .where((entry) => entry.application.status == 'interview')
            .toList();

        if (interviews.isEmpty) {
          return const StateMessage(
            title: 'Sin entrevistas',
            message: 'Aún no tienes entrevistas asignadas.',
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              context.read<MyApplicationsCubit>().loadMyApplications(),
          child: InterviewsList(interviews: interviews),
        );
      },
    );
  }
}

class InterviewsList extends StatelessWidget {
  const InterviewsList({super.key, required this.interviews});

  final List<CandidateApplicationEntry> interviews;

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
          itemCount: interviews.length,
          itemBuilder: (context, index) {
            return _buildInterviewCard(context, interviews[index]);
          },
        );
      },
    );
  }

  Widget _buildInterviewCard(
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
    final salary = offer?.formattedSalary;
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
      heroTag: entry.application.id ?? entry.application.jobOfferId,
      onTap: offer == null
          ? null
          : () => context.push('/job-offer/${offer.id}'),
    );
  }
}
