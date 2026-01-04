import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class CompanyHomeDashboard extends StatefulWidget {
  const CompanyHomeDashboard({super.key});

  @override
  State<CompanyHomeDashboard> createState() => _CompanyHomeDashboardState();
}

class _CompanyHomeDashboardState extends State<CompanyHomeDashboard> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        const _HomeHeader(),
        const SizedBox(height: 16),
        _OffersSummaryCard(
          onLoadCandidates: () => _loadApplicantsForAllOffers(context),
        ),
        const SizedBox(height: 12),
        _CandidatesSummaryCard(
          onLoadCandidates: () => _loadApplicantsForAllOffers(context),
        ),
      ],
    );
  }

  void _loadApplicantsForAllOffers(BuildContext context) {
    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return;

    final offersState = context.read<CompanyJobOffersCubit>().state;
    final offers = offersState.offers;
    if (offers.isEmpty) return;

    final applicantsCubit = context.read<OfferApplicantsCubit>();
    for (final offer in offers) {
      final status =
          applicantsCubit.state.statuses[offer.id] ??
          OfferApplicantsStatus.initial;
      if (status != OfferApplicantsStatus.loading) {
        applicantsCubit.loadApplicants(
          offerId: offer.id,
          companyUid: companyUid,
        );
      }
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'HOME',
          style: TextStyle(
            color: muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Resumen rápido de tus ofertas y candidatos.',
          style: TextStyle(color: muted, fontSize: 15, height: 1.4),
        ),
      ],
    );
  }
}

class _OffersSummaryCard extends StatelessWidget {
  const _OffersSummaryCard({required this.onLoadCandidates});

  final VoidCallback onLoadCandidates;

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
        builder: (context, state) {
          if (state.status == CompanyJobOffersStatus.loading ||
              state.status == CompanyJobOffersStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final offers = state.offers;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OFERTAS PUBLICADAS',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${offers.length}',
                style: const TextStyle(
                  color: ink,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (offers.isEmpty)
                const Text(
                  'Aún no has publicado ofertas.',
                  style: TextStyle(color: muted, height: 1.4),
                )
              else
                Column(
                  children: [
                    for (final offer in offers.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OfferRow(offer: offer),
                      ),
                  ],
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onLoadCandidates,
                  icon: const Icon(Icons.refresh_outlined, size: 18),
                  label: const Text('Actualizar candidatos'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final JobOffer offer;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.work_outline, color: ink, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                offer.location,
                style: const TextStyle(color: muted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CandidatesSummaryCard extends StatelessWidget {
  const _CandidatesSummaryCard({required this.onLoadCandidates});

  final VoidCallback onLoadCandidates;

  @override
  Widget build(BuildContext context) {
    const border = Color(0xFFE2E8F0);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: BlocBuilder<OfferApplicantsCubit, OfferApplicantsState>(
        builder: (context, state) {
          final candidates = _uniqueCandidates(state);
          final isLoading = state.statuses.values.any(
            (s) => s == OfferApplicantsStatus.loading,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CANDIDATOS',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${candidates.length}',
                style: const TextStyle(
                  color: ink,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading && candidates.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (candidates.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Todavía no hay candidatos cargados en el resumen.',
                      style: TextStyle(color: muted, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: onLoadCandidates,
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Cargar candidatos'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    for (final candidate in candidates.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CandidateRow(candidate: candidate),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CandidateSummary {
  const _CandidateSummary({
    required this.candidateUid,
    required this.displayName,
  });

  final String candidateUid;
  final String displayName;
}

List<_CandidateSummary> _uniqueCandidates(OfferApplicantsState state) {
  final byUid = <String, _CandidateSummary>{};
  for (final applications in state.applicants.values) {
    for (final application in applications) {
      final uid = application.candidateUid.trim();
      if (uid.isEmpty) continue;
      if (byUid.containsKey(uid)) continue;
      final displayName =
          (application.candidateName?.trim().isNotEmpty == true)
              ? application.candidateName!.trim()
              : (application.candidateEmail?.trim().isNotEmpty == true)
              ? application.candidateEmail!.trim()
              : uid;
      byUid[uid] = _CandidateSummary(candidateUid: uid, displayName: displayName);
    }
  }
  return byUid.values.toList();
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate});

  final _CandidateSummary candidate;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: ink,
          foregroundColor: Colors.white,
          child: Text(candidate.displayName.substring(0, 1).toUpperCase()),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            candidate.displayName,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.chevron_right, color: muted),
      ],
    );
  }
}
