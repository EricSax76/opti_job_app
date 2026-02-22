import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applicants/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({
    super.key,
    required this.candidate,
    this.candidateProfile,
  });

  final CandidateGroup candidate;
  final Candidate? candidateProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final avatarBg = colorScheme.primary;
    final avatarFg = colorScheme.onPrimary;
    const ok = Color(0xFF16A34A); // Success color
    final bool? hasCoverLetter = candidateProfile?.hasCoverLetter;
    final bool? hasVideoCurriculum = candidateProfile?.hasVideoCurriculum;

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
        onTap: candidate.entries.isEmpty
            ? null
            : () => _openCvPicker(context, candidate),
        leading: CircleAvatar(
          backgroundColor: avatarBg,
          foregroundColor: avatarFg,
          child: Text(candidate.displayName.substring(0, 1).toUpperCase()),
        ),
        title: Text(
          candidate.displayName,
          style: TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  label: 'Video',
                  value: hasVideoCurriculum,
                ),
              ],
            ),
          ],
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

  void _openCvPicker(
    BuildContext context,
    CandidateGroup candidate,
  ) {
    if (candidate.entries.isEmpty) return;

    // By user request, we skip the intermediate offer selection step in the "Candidates" tab.
    // We just pick the first offer context to open the CV directly.
    final entry = candidate.entries.first;
    _openApplicantCv(
      context: context,
      offerId: entry.offerId,
      candidateUid: candidate.candidateUid,
    );
  }

  void _openApplicantCv({
    required BuildContext context,
    required String offerId,
    required String candidateUid,
  }) {
    context.pushNamed(
      'company-applicant-cv',
      pathParameters: {'offerId': offerId, 'uid': candidateUid},
    );
  }
}
