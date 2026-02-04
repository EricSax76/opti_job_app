import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';

class DashboardCandidatesCard extends StatelessWidget {
  const DashboardCandidatesCard({super.key, required this.onLoadCandidates});

  final VoidCallback onLoadCandidates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? colorScheme.surface;
    final border = colorScheme.outline;
    final muted = colorScheme.onSurfaceVariant;
    final ink = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(uiCardRadius),
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
              Text(
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
                style: TextStyle(
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
                    Text(
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
      final displayName = (application.candidateName?.trim().isNotEmpty == true)
          ? application.candidateName!.trim()
          : (application.candidateEmail?.trim().isNotEmpty == true)
          ? application.candidateEmail!.trim()
          : uid;
      byUid[uid] = _CandidateSummary(
        candidateUid: uid,
        displayName: displayName,
      );
    }
  }
  return byUid.values.toList();
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate});
  final _CandidateSummary candidate;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: Text(candidate.displayName.substring(0, 1).toUpperCase()),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            candidate.displayName,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      ],
    );
  }
}
