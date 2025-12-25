import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/ai/models/ai_exceptions.dart';
import 'package:opti_job_app/modules/ai/models/ai_match_result.dart';
import 'package:opti_job_app/modules/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/aplications/ui/application_status.dart';
import 'package:opti_job_app/modules/candidates/cubits/candidate_auth_state.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/cubit/job_offer_detail_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

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
    if (state.status == JobOfferDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == JobOfferDetailStatus.failure && state.offer == null) {
      return Center(
        child: Text(state.errorMessage ?? 'No se pudo cargar la oferta.'),
      );
    }

    final offer = state.offer;
    if (offer == null) {
      return const Center(child: Text('Oferta no encontrada.'));
    }

    final isApplying = state.status == JobOfferDetailStatus.applying;
    final application = state.application;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OfferHeader(title: offer.title, location: offer.location),
        if (application != null) ...[
          const SizedBox(height: 10),
          applicationStatusChip(application.status),
        ],
        const SizedBox(height: 16),
        Expanded(child: OfferDetails(offer: offer)),
        const SizedBox(height: 16),
        OfferActions(
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
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Future<void> _showOfferMatch(BuildContext context, JobOffer offer) async {
    final candidate = authState.candidate;
    if (candidate == null) return;

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
    );

    try {
      final curriculumRepository = context.read<CurriculumRepository>();
      final aiRepository = context.read<AiRepository>();
      final locale = Localizations.localeOf(context).toLanguageTag();

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
      Navigator.of(context).pop(); // loading
      await _showMatchResultDialog(context, result);
    } on AiConfigurationException catch (error) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on AiRequestException catch (error) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular el match.')),
      );
    }
  }

  Future<void> _showMatchResultDialog(
    BuildContext context,
    AiMatchResult result,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Match: ${result.score}/100'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.summary != null) ...[
                  Text(result.summary!),
                  const SizedBox(height: 12),
                ],
                if (result.reasons.isNotEmpty) ...[
                  const Text(
                    'Puntos clave',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final reason in result.reasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(reason)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}

class OfferHeader extends StatelessWidget {
  const OfferHeader({super.key, required this.title, required this.location});

  final String title;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(location),
      ],
    );
  }
}

class OfferDetails extends StatelessWidget {
  const OfferDetails({super.key, required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer.description),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'Tipología',
            value: offer.jobType ?? 'No especificada',
          ),
          _InfoRow(
            label: 'Educación requerida',
            value: offer.education ?? 'No especificada',
          ),
          if (offer.salaryMin != null || offer.salaryMax != null)
            _InfoRow(
              label: 'Salario',
              value:
                  '${offer.salaryMin ?? 'N/D'}'
                  '${offer.salaryMax != null ? ' - ${offer.salaryMax}' : ''}',
            ),
          if (offer.keyIndicators != null)
            _InfoRow(label: 'Indicadores clave', value: offer.keyIndicators!),
        ],
      ),
    );
  }
}

class OfferActions extends StatelessWidget {
  const OfferActions({
    super.key,
    required this.isAuthenticated,
    required this.isApplying,
    required this.applicationStatus,
    required this.onApply,
    required this.onMatch,
    required this.onBack,
  });

  final bool isAuthenticated;
  final bool isApplying;
  final String? applicationStatus;
  final VoidCallback onApply;
  final VoidCallback? onMatch;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final hasApplied = applicationStatus != null;
    return Wrap(
      spacing: 12,
      children: [
        if (isAuthenticated)
          FilledButton(
            onPressed: (isApplying || hasApplied) ? null : onApply,
            child: isApplying
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    hasApplied
                        ? 'Postulación: ${applicationStatusLabel(applicationStatus!)}'
                        : 'Postularme',
                  ),
          ),
        if (isAuthenticated)
          OutlinedButton.icon(
            onPressed: isApplying ? null : onMatch,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Match'),
          ),
        OutlinedButton(
          onPressed: isApplying ? null : onBack,
          child: const Text('Volver'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
