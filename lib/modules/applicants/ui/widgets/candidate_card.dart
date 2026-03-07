import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/logic/company_candidates_logic.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({super.key, required this.candidate});

  final CandidateGroup candidate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final avatarBg = colorScheme.primary;
    final avatarFg = colorScheme.onPrimary;
    const ok = Color(0xFF16A34A); // Success color
    final isAnonymousScreening = candidate.isAnonymousScreening;
    final displayName = isAnonymousScreening
        ? candidate.anonymizedLabel
        : candidate.displayName;
    final hasNavigableEntry = candidate.entries.any(
      (entry) => (entry.applicationId ?? '').trim().isNotEmpty,
    );
    final hasCoverLetter = candidate.entries.any(
      (entry) => entry.hasCoverLetter,
    );
    final hasVideoCurriculum = candidate.entries.any(
      (entry) => entry.hasVideoCurriculum,
    );
    final canViewVideoCurriculum = candidate.entries.any(
      (entry) => entry.canViewVideoCurriculum,
    );

    Widget statusPill({
      required IconData icon,
      required String label,
      required bool? value,
    }) {
      final isYes = value == true;
      final isNo = value == false;
      final color = isYes ? ok : muted;
      final text = isYes
          ? '$label: Sí'
          : isNo
          ? '$label: No'
          : '$label: ...';
      return InfoPill(
        icon: icon,
        label: text,
        backgroundColor: colorScheme.surface,
        borderColor: colorScheme.outline,
        textColor: color,
        iconColor: color,
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: uiTileRadius,
      backgroundColor: surfaceContainer,
      borderColor: colorScheme.outline,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap:
            candidate.entries.isEmpty ||
                isAnonymousScreening ||
                !hasNavigableEntry
            ? null
            : () => _openCvPicker(context, candidate),
        leading: CircleAvatar(
          backgroundColor: avatarBg,
          foregroundColor: avatarFg,
          child: Text(displayName.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          displayName,
          style: TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAnonymousScreening) ...[
              Text(
                'Perfil anonimizado en fase inicial de criba.',
                style: TextStyle(color: muted, height: 1.35),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              candidate.entries.map((e) => e.offerTitle).join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted, height: 1.35),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                statusPill(
                  icon: Icons.mail_outline,
                  label: 'Carta',
                  value: hasCoverLetter,
                ),
                statusPill(
                  icon: Icons.videocam_outlined,
                  label: canViewVideoCurriculum ? 'Video' : 'Video (oculto)',
                  value: canViewVideoCurriculum ? hasVideoCurriculum : null,
                ),
              ],
            ),
          ],
        ),
        trailing: TextButton(
          onPressed:
              candidate.entries.isEmpty ||
                  isAnonymousScreening ||
                  !hasNavigableEntry
              ? null
              : () => _openCvPicker(context, candidate),
          child: Text(isAnonymousScreening ? 'Anónimo' : 'CV'),
        ),
      ),
    );
  }

  void _openCvPicker(BuildContext context, CandidateGroup candidate) {
    if (candidate.entries.isEmpty) return;

    // By user request, we skip the intermediate offer selection step in the "Candidates" tab.
    // We just pick the first offer context to open the CV directly.
    final entry = candidate.entries.firstWhere(
      (item) => (item.applicationId ?? '').trim().isNotEmpty,
      orElse: () => candidate.entries.first,
    );
    final applicationId = (entry.applicationId ?? '').trim();
    if (applicationId.isEmpty) return;
    _openApplicantCv(
      context: context,
      offerId: entry.offerId,
      candidateUid: candidate.candidateUid,
      applicationId: applicationId,
    );
  }

  void _openApplicantCv({
    required BuildContext context,
    required String offerId,
    required String candidateUid,
    required String applicationId,
  }) {
    context.pushNamed(
      'company-applicant-cv',
      pathParameters: {'offerId': offerId, 'candidateUid': candidateUid},
      queryParameters: {'applicationId': applicationId},
    );
  }
}
