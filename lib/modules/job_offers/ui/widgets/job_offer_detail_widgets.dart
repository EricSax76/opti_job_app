import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/applications/ui/application_status.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_actions.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_details.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_header.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_match_dialog.dart';

void handleJobOfferDetailMessages(
  BuildContext context,
  JobOfferDetailState state,
) {
  if (state.successMessage != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          backgroundColor: Colors.green,
        ),
      );
    context.read<JobOfferDetailCubit>().clearMessages();
  }

  if (state.errorMessage != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    context.read<JobOfferDetailCubit>().clearMessages();
  }
}

class JobOfferDetailBody extends StatelessWidget {
  const JobOfferDetailBody({
    super.key,
    required this.state,
    required this.authState,
  });

  final JobOfferDetailState state;
  final CandidateAuthState authState;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? uiDarkMuted : uiMuted;
    final border = isDark ? uiDarkBorder : uiBorder;
    final cardBackground = isDark ? uiDarkSurface : Colors.white;

    if (state.status == JobOfferDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == JobOfferDetailStatus.failure && state.offer == null) {
      final message = state.errorMessage ?? 'No se pudo cargar la oferta.';
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(uiCardRadius),
            border: Border.all(color: border),
          ),
          child: Text(message, style: TextStyle(color: muted, height: 1.4)),
        ),
      );
    }

    final offer = state.offer;
    if (offer == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(uiCardRadius),
            border: Border.all(color: border),
          ),
          child: Text(
            'Oferta no encontrada.',
            style: TextStyle(color: muted, height: 1.4),
          ),
        ),
      );
    }

    final isApplying = state.status == JobOfferDetailStatus.applying;
    final application = state.application;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            String? avatarUrl = offer.companyAvatarUrl;
            if ((avatarUrl == null || avatarUrl.trim().isEmpty) &&
                offer.companyId != null) {
              final jobOffersState = context.read<JobOffersCubit>().state;
              avatarUrl =
                  jobOffersState.companiesById[offer.companyId!]?.avatarUrl;
            }
            return JobOfferHeader(
              offer: offer,
              companyAvatarUrl: avatarUrl,
              statusChip: application == null
                  ? null
                  : applicationStatusChip(application.status),
            );
          },
        ),
        const SizedBox(height: 14),
        Expanded(child: JobOfferDetails(offer: offer)),
        const SizedBox(height: 14),
        JobOfferActions(
          isAuthenticated: authState.isAuthenticated,
          isApplying: isApplying,
          applicationStatus: application?.status,
          onApply: () {
            final candidate = authState.candidate;
            if (candidate != null) {
              context.read<JobOfferDetailCubit>().apply(
                candidate: candidate,
                offer: offer,
              );
            }
          },
          onMatch: authState.candidate == null
              ? null
              : () => _showOfferMatch(context, offer),
          onBack: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/job-offer');
          },
        ),
      ],
    );
  }

  Future<void> _showOfferMatch(BuildContext context, JobOffer offer) async {
    final candidate = authState.candidate;
    if (candidate == null) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var isLoadingDialogOpen = true;
    void closeLoadingDialogIfNeeded() {
      if (!isLoadingDialogOpen || !rootNavigator.mounted) return;
      rootNavigator.pop();
      isLoadingDialogOpen = false;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text('Calculando match'),
          content: Row(
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Analizando tu CV contra la oferta...')),
            ],
          ),
        );
      },
    ).whenComplete(() {
      isLoadingDialogOpen = false;
    });

    try {
      final curriculumRepository = context.read<CurriculumRepository>();
      final aiRepository = context.read<AiRepository>();
      const locale = 'es-ES';

      final curriculum = await curriculumRepository.fetchCurriculum(
        candidate.uid,
      );
      if (!context.mounted) return;

      final result = await aiRepository.matchOfferCandidate(
        curriculum: curriculum,
        offer: offer,
        locale: locale,
      );

      if (!context.mounted) return;
      closeLoadingDialogIfNeeded();
      await showDialog<void>(
        context: context,
        builder: (context) => JobOfferMatchResultDialog(result: result),
      );
    } on AiConfigurationException catch (error) {
      if (!context.mounted) return;
      closeLoadingDialogIfNeeded();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on AiRequestException catch (error) {
      if (!context.mounted) return;
      closeLoadingDialogIfNeeded();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) return;
      closeLoadingDialogIfNeeded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular el match.')),
      );
    }
  }
}
