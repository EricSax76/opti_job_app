import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

class ApplicantCurriculumHeader extends StatelessWidget {
  const ApplicantCurriculumHeader({
    super.key,
    required this.candidate,
    required this.hasCurriculum,
    required this.isExporting,
    required this.isMatching,
    required this.onExport,
    required this.onMatch,
  });

  final Candidate candidate;
  final bool hasCurriculum;
  final bool isExporting;
  final bool isMatching;
  final VoidCallback onExport;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final fullName = '${candidate.name} ${candidate.lastName}'.trim();
    final displayName = fullName.isEmpty ? candidate.email : fullName;

    return AppCard(
      padding: const EdgeInsets.all(uiSpacing20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;

          final header = Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: Text(_initial(candidate)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidate.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          );

          final buttonStyle = OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
          );

          final exportButton = OutlinedButton.icon(
            onPressed: isExporting || !hasCurriculum ? null : onExport,
            style: buttonStyle,
            icon: isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(isExporting ? 'Exportando...' : 'Exportar PDF'),
          );

          final matchButton = OutlinedButton.icon(
            onPressed: isMatching || !hasCurriculum ? null : onMatch,
            style: buttonStyle,
            icon: isMatching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(isMatching ? 'Analizando...' : 'Match IA'),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [exportButton, matchButton],
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: header),
              const SizedBox(width: 10),
              exportButton,
              const SizedBox(width: 10),
              matchButton,
            ],
          );
        },
      ),
    );
  }

  String _initial(Candidate candidate) {
    final raw =
        (candidate.name.trim().isNotEmpty ? candidate.name : candidate.email)
            .trim();
    if (raw.isEmpty) return '?';
    return raw.substring(0, 1).toUpperCase();
  }
}
