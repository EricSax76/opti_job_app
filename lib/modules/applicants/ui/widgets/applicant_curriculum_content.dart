import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_curriculum_header.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_read_only_view.dart';

class ApplicantCurriculumContent extends StatelessWidget {
  const ApplicantCurriculumContent({
    super.key,
    required this.candidate,
    required this.curriculum,
    required this.isExporting,
    required this.isMatching,
    required this.onExport,
    required this.onMatch,
  });

  final Candidate candidate;
  final Curriculum curriculum;
  final bool isExporting;
  final bool isMatching;
  final VoidCallback onExport;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    final hasCurriculum = curriculum.hasContent;
    final coverLetterText = candidate.coverLetter?.text.trim() ?? '';
    final hasCoverLetter = candidate.hasCoverLetter;
    final hasVideoCurriculum = candidate.hasVideoCurriculum;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ApplicantCurriculumHeader(
                candidate: candidate,
                hasCurriculum: hasCurriculum,
                isExporting: isExporting,
                isMatching: isMatching,
                onExport: onExport,
                onMatch: onMatch,
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Curriculum',
                child: hasCurriculum
                    ? CurriculumReadOnlyView(curriculum: curriculum)
                    : InlineStateMessage(
                        icon: Icons.description_outlined,
                        message: 'El aplicante aún no tiene un CV cargado.',
                        color: muted,
                      ),
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Carta de presentación',
                padding: EdgeInsets.zero,
                child: _DetailPanel(
                  child: hasCoverLetter
                      ? SelectableText(
                          coverLetterText,
                          style: TextStyle(color: muted, height: 1.5),
                        )
                      : InlineStateMessage(
                          icon: Icons.description_outlined,
                          message:
                              'El aplicante no adjuntó una carta de presentación.',
                          color: muted,
                        ),
                ),
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Video curriculum',
                padding: EdgeInsets.zero,
                child: _DetailPanel(
                  child: Row(
                    children: [
                      Icon(Icons.videocam_outlined, color: muted),
                      const SizedBox(width: uiSpacing12),
                      Expanded(
                        child: Text(
                          hasVideoCurriculum
                              ? 'Video cargado (privado)'
                              : 'No adjuntó video curriculum',
                          style: TextStyle(color: muted, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      borderRadius: uiTileRadius,
      backgroundColor: colorScheme.surfaceContainerHighest,
      borderColor: colorScheme.outline,
      child: child,
    );
  }
}
