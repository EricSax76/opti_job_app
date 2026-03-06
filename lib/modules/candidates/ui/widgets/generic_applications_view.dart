import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applications/cubits/my_applications_cubit.dart';
import 'package:opti_job_app/modules/applications/models/candidate_application_entry.dart';
import 'package:opti_job_app/modules/applications/ui/widgets/application_status_badge.dart';
import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_offer_card_base.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_extensions.dart';

class GenericApplicationsView extends StatelessWidget {
  const GenericApplicationsView({
    super.key,
    required this.heroTagPrefix,
    required this.emptyTitle,
    required this.emptyMessage,
    this.filter,
  });

  final String heroTagPrefix;
  final String emptyTitle;
  final String emptyMessage;
  final bool Function(CandidateApplicationEntry entry)? filter;

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
            title: 'No se pudieron cargar los datos',
            message:
                state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
          );
        }

        final applications = filter != null
            ? state.applications.where(filter!).toList()
            : state.applications;

        if (applications.isEmpty) {
          return StateMessage(title: emptyTitle, message: emptyMessage);
        }

        return RefreshIndicator(
          onRefresh: () => context.read<MyApplicationsCubit>().refresh(),
          child: ApplicationsList(
            applications: applications,
            heroTagPrefix: heroTagPrefix,
          ),
        );
      },
    );
  }
}

class ApplicationsList extends StatelessWidget {
  const ApplicationsList({
    super.key,
    required this.applications,
    required this.heroTagPrefix,
  });

  final List<CandidateApplicationEntry> applications;
  final String heroTagPrefix;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 1;
        if (crossAxisCount == 1) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildApplicationCard(context, applications[index], index);
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 240,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            return _buildApplicationCard(context, applications[index], index);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    CandidateApplicationEntry entry,
    int index,
  ) {
    final offer = entry.offer;
    final fallbackTitle = entry.application.jobOfferTitle;
    final title =
        offer?.title ??
        ((fallbackTitle != null && fallbackTitle.trim().isNotEmpty)
            ? fallbackTitle
            : 'Oferta');
    final statusChip = ApplicationStatusBadge.fromString(
      entry.application.status,
    );
    final company = offer?.companyName ?? 'Empresa no especificada';
    final salary = offer?.formattedSalary;
    final location = offer?.location;
    final feedback = _CandidateMicroFeedback.fromApplication(
      entry.application.candidateFeedback,
    );
    final modality = offer == null
        ? null
        : (offer.jobType ?? 'Modalidad no especificada');

    final heroId = entry.application.id ?? entry.application.jobOfferId;

    return CandidateOfferCardBase(
      title: title,
      company: company,
      description: feedback?.message ?? offer?.description,
      avatarUrl: offer?.companyAvatarUrl,
      salary: salary,
      location: location,
      modality: modality,
      tags: feedback?.actions.take(2).toList(growable: false),
      topRightBadge: statusChip,
      heroTag: '$heroTagPrefix-$index-$heroId',
      heroTagPrefix: 'application_avatar',
      onTap: offer == null
          ? null
          : () => context.push('/job-offer/${offer.id}'),
    );
  }
}

class _CandidateMicroFeedback {
  const _CandidateMicroFeedback({required this.message, required this.actions});

  final String message;
  final List<String> actions;

  static _CandidateMicroFeedback? fromApplication(
    Map<String, dynamic> candidateFeedback,
  ) {
    if (candidateFeedback.isEmpty) return null;
    final latest = candidateFeedback['latest'];
    if (latest is! Map) return null;
    final latestMap = Map<String, dynamic>.from(latest);
    final message = (latestMap['message'] as String?)?.trim() ?? '';
    final actions =
        (latestMap['actions'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
    if (message.isEmpty && actions.isEmpty) return null;
    return _CandidateMicroFeedback(message: message, actions: actions);
  }
}
