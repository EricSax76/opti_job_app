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
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);

    if (state.status == JobOfferDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == JobOfferDetailStatus.failure && state.offer == null) {
      final message = state.errorMessage ?? 'No se pudo cargar la oferta.';
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: Text(message, style: const TextStyle(color: muted, height: 1.4)),
        ),
      );
    }

    final offer = state.offer;
    if (offer == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: const Text(
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
        OfferHeader(
          offer: offer,
          statusChip: application == null
              ? null
              : applicationStatusChip(application.status),
        ),
        const SizedBox(height: 14),
        Expanded(child: OfferDetails(offer: offer)),
        const SizedBox(height: 14),
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
                if (result.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Recomendaciones',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final recommendation in result.recommendations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(recommendation)),
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
  const OfferHeader({
    super.key,
    required this.offer,
    this.statusChip,
  });

  final JobOffer offer;
  final Widget? statusChip;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);

    final title = offer.title.trim().isEmpty ? 'Oferta' : offer.title.trim();
    final company =
        offer.companyName?.trim().isNotEmpty == true
            ? offer.companyName!.trim()
            : 'Empresa no especificada';
    final salary = _formatSalary(offer);
    final modality =
        offer.jobType?.trim().isNotEmpty == true
            ? offer.jobType!.trim()
            : 'Modalidad no especificada';
    final location =
        offer.location.trim().isEmpty ? 'Ubicación no especificada' : offer.location;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.work_outline, color: ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              if (statusChip != null) ...[
                const SizedBox(width: 12),
                statusChip!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (salary != null) _InfoPill(icon: Icons.payments_outlined, label: salary),
              _InfoPill(icon: Icons.home_work_outlined, label: modality),
              _InfoPill(icon: Icons.place_outlined, label: location),
            ],
          ),
        ],
      ),
    );
  }
}

class OfferDetails extends StatelessWidget {
  const OfferDetails({super.key, required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);

    final description =
        offer.description.trim().isEmpty ? 'Sin descripción.' : offer.description.trim();
    final salary = _formatSalary(offer) ?? 'No especificado';
    final education =
        offer.education?.trim().isNotEmpty == true ? offer.education!.trim() : 'No especificada';
    final keyIndicators =
        offer.keyIndicators?.trim().isNotEmpty == true ? offer.keyIndicators!.trim() : null;

    return SingleChildScrollView(
      child: Column(
        children: [
          _SectionCard(
            title: 'Descripción',
            child: Text(
              description,
              style: const TextStyle(color: ink, height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Detalles',
            child: Column(
              children: [
                _DetailRow(label: 'Salario', value: salary),
                _DetailRow(
                  label: 'Modalidad',
                  value: offer.jobType ?? 'No especificada',
                ),
                _DetailRow(label: 'Educación', value: education),
                if (keyIndicators != null)
                  _DetailRow(label: 'Indicadores clave', value: keyIndicators),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Revisa los detalles y postúlate cuando estés listo.',
                    style: TextStyle(color: muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
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
    const ink = Color(0xFF0F172A);
    final hasApplied = applicationStatus != null;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (isAuthenticated)
          FilledButton(
            onPressed: (isApplying || hasApplied) ? null : onApply,
            style: FilledButton.styleFrom(backgroundColor: ink),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const border = Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF64748B);
    const border = Color(0xFFE2E8F0);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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
