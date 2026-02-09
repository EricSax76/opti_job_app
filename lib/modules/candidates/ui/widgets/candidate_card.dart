import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/companies/logic/company_candidates_logic.dart';
import 'package:opti_job_app/modules/applications/ui/application_status.dart';
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
    final border = colorScheme.outline;
    final avatarBg = colorScheme.primary;
    final avatarFg = colorScheme.onPrimary;
    const ok = Color(0xFF16A34A); // Success color
    final bool? hasCoverLetter = candidateProfile?.hasCoverLetter;
    final bool? hasVideoCurriculum = candidateProfile?.hasVideoCurriculum;

    Widget badge({
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
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
                badge(
                  icon: Icons.mail_outline,
                  label: 'Carta',
                  value: hasCoverLetter,
                ),
                badge(
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

  void _openCvPicker(BuildContext context, CandidateGroup candidate) {
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
                    subtitle: Text(
                      'Estado: ${applicationStatusLabel(entry.status)}',
                    ),
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
