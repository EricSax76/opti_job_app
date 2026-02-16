import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/features/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_cubit.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubits/job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/detail/job_offer_detail_content.dart';
import 'package:opti_job_app/modules/job_offers/ui/widgets/job_offer_match_dialog.dart';

class JobOfferDetailContainer extends StatelessWidget {
  const JobOfferDetailContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<CandidateAuthCubit>().state;
    final candidate = authState.candidate;

    return BlocListener<JobOfferDetailCubit, JobOfferDetailState>(
      listenWhen: (previous, current) =>
          previous.successMessage != current.successMessage ||
          previous.errorMessage != current.errorMessage,
      listener: _handleDetailMessages,
      child: BlocBuilder<JobOfferDetailCubit, JobOfferDetailState>(
        builder: (context, state) {
          final offer = state.offer;

          return JobOfferDetailContent(
            state: state,
            isAuthenticated: authState.isAuthenticated,
            companyAvatarUrl: offer == null
                ? null
                : _resolveCompanyAvatarUrl(context, offer),
            onApply: () {
              if (candidate == null || offer == null) return;
              context.read<JobOfferDetailCubit>().apply(
                candidate: candidate,
                offer: offer,
              );
            },
            onMatch: (candidate == null || offer == null)
                ? null
                : () => _showOfferMatch(
                    context,
                    candidateUid: candidate.uid,
                    offer: offer,
                  ),
            onBack: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go('/job-offer');
            },
          );
        },
      ),
    );
  }

  void _handleDetailMessages(BuildContext context, JobOfferDetailState state) {
    if (state.successMessage case final message?) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      context.read<JobOfferDetailCubit>().clearMessages();
      return;
    }

    if (state.errorMessage case final message?) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      context.read<JobOfferDetailCubit>().clearMessages();
    }
  }

  String? _resolveCompanyAvatarUrl(BuildContext context, JobOffer offer) {
    final offerAvatar = offer.companyAvatarUrl?.trim();
    if (offerAvatar != null && offerAvatar.isNotEmpty) {
      return offerAvatar;
    }

    final companyId = offer.companyId;
    if (companyId == null) return null;

    return context
        .read<JobOffersCubit>()
        .state
        .companiesById[companyId]
        ?.avatarUrl;
  }

  Future<void> _showOfferMatch(
    BuildContext context, {
    required String candidateUid,
    required JobOffer offer,
  }) async {
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
        candidateUid,
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
