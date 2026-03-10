import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/features/video_curriculum/widgets/uploaded_video_status_card.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/applicant_curriculum_header.dart';
import 'package:opti_job_app/modules/applicants/ui/widgets/selective_disclosure_verification_panel.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/curriculum/models/curriculum.dart';
import 'package:opti_job_app/modules/curriculum/ui/widgets/curriculum_read_only_view.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/applicant_evaluation_section.dart';

class ApplicantCurriculumContent extends StatelessWidget {
  const ApplicantCurriculumContent({
    super.key,
    required this.candidate,
    required this.curriculum,
    required this.offerId,
    required this.applicationId,
    required this.companyUid,
    required this.hasVideoCurriculum,
    required this.canViewVideoCurriculum,
    required this.isExporting,
    required this.isMatching,
    required this.onExport,
    required this.onMatch,
  });

  final Candidate candidate;
  final Curriculum curriculum;
  final String offerId;
  final String? applicationId;
  final String? companyUid;
  final bool hasVideoCurriculum;
  final bool canViewVideoCurriculum;
  final bool isExporting;
  final bool isMatching;
  final VoidCallback onExport;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    final hasCurriculum = curriculum.hasContent;
    final normalizedApplicationId = applicationId?.trim() ?? '';
    final resolvedCompanyUid = companyUid?.trim() ?? '';
    final coverLetterText = candidate.coverLetter?.text.trim() ?? '';
    final hasCoverLetter = candidate.hasCoverLetter;
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
                    ? CurriculumReadOnlyView(
                        curriculum: curriculum,
                        avatarUrl: candidate.avatarUrl,
                      )
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
                  child: _ApplicantVideoCurriculumPanel(
                    video: candidate.videoCurriculum,
                    hasVideoCurriculum: hasVideoCurriculum,
                    canViewVideoCurriculum: canViewVideoCurriculum,
                  ),
                ),
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Evaluaciones y aprobaciones',
                padding: EdgeInsets.zero,
                child: _DetailPanel(
                  child: ApplicantEvaluationSection(
                    applicationId: normalizedApplicationId,
                    jobOfferId: offerId,
                    companyUid: resolvedCompanyUid,
                  ),
                ),
              ),
              const SizedBox(height: uiSpacing16),
              SectionCard(
                title: 'Verificación de credenciales (ZKP)',
                padding: EdgeInsets.zero,
                child: _DetailPanel(
                  child: SelectiveDisclosureVerificationPanel(
                    candidateUid: candidate.uid,
                    offerId: offerId,
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

class _ApplicantVideoCurriculumPanel extends StatelessWidget {
  const _ApplicantVideoCurriculumPanel({
    required this.video,
    required this.hasVideoCurriculum,
    required this.canViewVideoCurriculum,
  });

  final CandidateVideoCurriculum? video;
  final bool hasVideoCurriculum;
  final bool canViewVideoCurriculum;

  @override
  Widget build(BuildContext context) {
    final storagePath = video?.storagePath.trim() ?? '';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (!canViewVideoCurriculum) {
      return _buildStatusRow(
        context,
        icon: Icons.lock_outline,
        message: 'Video no visible en esta etapa.',
        trailing: Text(
          'Restringido',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
        ),
      );
    }

    if (!hasVideoCurriculum) {
      return _buildStatusRow(
        context,
        icon: Icons.videocam_off_outlined,
        message: 'No adjuntó video curriculum.',
      );
    }

    if (storagePath.isEmpty) {
      return _buildStatusRow(
        context,
        icon: Icons.warning_amber_outlined,
        message:
            'Hay video disponible para esta etapa, pero falta la referencia del archivo.',
      );
    }

    return UploadedVideoStatusCard(video: video, embedded: true);
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required IconData icon,
    required String message,
    Widget? trailing,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, color: muted),
        const SizedBox(width: uiSpacing12),
        Expanded(
          child: Text(message, style: TextStyle(color: muted, height: 1.3)),
        ),
        if (trailing != null) ...[const SizedBox(width: uiSpacing8), trailing],
      ],
    );
  }
}
