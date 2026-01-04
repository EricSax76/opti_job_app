import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/job_offers/cubit/company_job_offers_cubit.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class CompanyCandidatesSection extends StatefulWidget {
  const CompanyCandidatesSection({super.key});

  @override
  State<CompanyCandidatesSection> createState() =>
      _CompanyCandidatesSectionState();
}

class _CompanyCandidatesSectionState extends State<CompanyCandidatesSection> {
  var _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadAllApplicants();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyJobOffersCubit, CompanyJobOffersState>(
      builder: (context, offersState) {
        if (offersState.status == CompanyJobOffersStatus.loading ||
            offersState.status == CompanyJobOffersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (offersState.status == CompanyJobOffersStatus.failure) {
          return _message(
            offersState.errorMessage ??
                'No se pudieron cargar tus ofertas. Intenta refrescar.',
          );
        }

        if (offersState.offers.isEmpty) {
          return _message(
            'Aún no hay ofertas publicadas. Publica una oferta para recibir candidatos.',
          );
        }

        final offerById = {for (final offer in offersState.offers) offer.id: offer};

        return BlocBuilder<OfferApplicantsCubit, OfferApplicantsState>(
          builder: (context, applicantsState) {
            final grouped = _groupByCandidate(
              applicantsState: applicantsState,
              offerById: offerById,
            );

            final isLoading = applicantsState.statuses.values.any(
              (s) => s == OfferApplicantsStatus.loading,
            );

            if (isLoading && grouped.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (grouped.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _message(
                    'Aún no hay candidatos cargados. Pulsa para cargar postulaciones de tus ofertas.',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _maybeLoadAllApplicants,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Cargar candidatos'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                for (final candidate in grouped)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CandidateCard(candidate: candidate),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _message(String text) {
    const border = Color(0xFFE2E8F0);
    const muted = Color(0xFF475569);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Text(text, style: const TextStyle(color: muted, height: 1.4)),
    );
  }

  void _maybeLoadAllApplicants() {
    if (_requestedInitialLoad) return;

    final companyUid = context.read<CompanyAuthCubit>().state.company?.uid;
    if (companyUid == null) return;
    final offersState = context.read<CompanyJobOffersCubit>().state;
    if (offersState.offers.isEmpty) return;

    final applicantsCubit = context.read<OfferApplicantsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final offer in offersState.offers) {
        final status =
            applicantsCubit.state.statuses[offer.id] ??
            OfferApplicantsStatus.initial;
        if (status == OfferApplicantsStatus.initial ||
            status == OfferApplicantsStatus.failure) {
          applicantsCubit.loadApplicants(
            offerId: offer.id,
            companyUid: companyUid,
          );
        }
      }
    });

    setState(() => _requestedInitialLoad = true);
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final _CandidateGroup candidate;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFC);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: candidate.entries.isEmpty
            ? null
            : () => _openCvPicker(context, candidate),
        leading: CircleAvatar(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          child: Text(candidate.displayName.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          candidate.displayName,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          candidate.entries.map((e) => e.offerTitle).join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: muted, height: 1.35),
        ),
        trailing: TextButton(
          onPressed: candidate.entries.isEmpty
              ? null
              : () => _openCvPicker(context, candidate),
          child: const Text('CV'),
        ),
      ),
    );
  }

  void _openCvPicker(BuildContext context, _CandidateGroup candidate) {
    if (candidate.entries.length == 1) {
      final entry = candidate.entries.first;
      context.push(
        '/company/offers/${entry.offerId}/applicants/${candidate.candidateUid}/cv',
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              ListTile(
                title: Text(
                  candidate.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Selecciona una oferta para ver el CV'),
              ),
              const SizedBox(height: 6),
              for (final entry in candidate.entries)
                Card(
                  child: ListTile(
                    title: Text(entry.offerTitle),
                    subtitle: Text('Estado: ${_statusLabel(entry.status)}'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        '/company/offers/${entry.offerId}/applicants/${candidate.candidateUid}/cv',
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CandidateGroup {
  const _CandidateGroup({
    required this.candidateUid,
    required this.displayName,
    required this.entries,
  });

  final String candidateUid;
  final String displayName;
  final List<_CandidateOfferEntry> entries;
}

class _CandidateOfferEntry {
  const _CandidateOfferEntry({
    required this.offerId,
    required this.offerTitle,
    required this.status,
  });

  final int offerId;
  final String offerTitle;
  final String status;
}

List<_CandidateGroup> _groupByCandidate({
  required OfferApplicantsState applicantsState,
  required Map<int, JobOffer> offerById,
}) {
  final byCandidate = <String, List<Application>>{};
  for (final apps in applicantsState.applicants.values) {
    for (final app in apps) {
      final uid = app.candidateUid.trim();
      if (uid.isEmpty) continue;
      (byCandidate[uid] ??= []).add(app);
    }
  }

  final result = <_CandidateGroup>[];
  byCandidate.forEach((candidateUid, apps) {
    apps.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    final first = apps.first;
    final displayName =
        (first.candidateName?.trim().isNotEmpty == true)
            ? first.candidateName!.trim()
            : (first.candidateEmail?.trim().isNotEmpty == true)
            ? first.candidateEmail!.trim()
            : candidateUid;

    final entries = <_CandidateOfferEntry>[];
    final seenOffers = <int>{};
    for (final app in apps) {
      if (!seenOffers.add(app.jobOfferId)) continue;
      final offerTitle =
          offerById[app.jobOfferId]?.title ??
          app.jobOfferTitle ??
          'Oferta #${app.jobOfferId}';
      entries.add(
        _CandidateOfferEntry(
          offerId: app.jobOfferId,
          offerTitle: offerTitle,
          status: app.status,
        ),
      );
    }

    result.add(
      _CandidateGroup(
        candidateUid: candidateUid,
        displayName: displayName,
        entries: entries,
      ),
    );
  });

  result.sort((a, b) => a.displayName.compareTo(b.displayName));
  return result;
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pendiente';
    case 'reviewing':
      return 'En revisión';
    case 'interview':
      return 'Entrevista';
    case 'accepted':
      return 'Aceptado';
    case 'rejected':
      return 'Rechazado';
    default:
      return status;
  }
}
