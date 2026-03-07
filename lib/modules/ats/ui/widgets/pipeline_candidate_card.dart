import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/modules/applicants/logic/candidate_anonymization_logic.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_cubit.dart';

class PipelineCandidateCard extends StatelessWidget {
  const PipelineCandidateCard({super.key, required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: application.id,
      onDragStarted: () => context.read<PipelineBoardCubit>().onDragStart(),
      onDragEnd: (details) => context.read<PipelineBoardCubit>().onDragEnd(),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(uiTileRadius),
        child: SizedBox(
          width: 250,
          child: _CardContent(application: application, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _CardContent(application: application),
      ),
      child: _CardContent(application: application),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.application, this.isDragging = false});

  final Application application;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAnonymousScreening = shouldAnonymizeApplication(application);
    final displayName = isAnonymousScreening
        ? buildAnonymizedCandidateLabel(
            application.candidateUid,
            anonymizedLabel: application.anonymizedLabel,
          )
        : (application.candidateName ?? 'Desconocido');
    final displayEmail = isAnonymousScreening
        ? 'Identidad oculta en criba inicial'
        : (application.candidateEmail ?? '');
    final tags = _buildTags(
      context: context,
      isAnonymousScreening: isAnonymousScreening,
    );
    final initial = _avatarInitial(displayName);

    return AppCard(
      borderRadius: uiTileRadius,
      borderColor: isDragging
          ? colorScheme.primary
          : colorScheme.outlineVariant,
      boxShadow: isDragging ? null : uiShadowSm,
      padding: const EdgeInsets.all(uiSpacing12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage:
                    !isAnonymousScreening &&
                        application.candidateAvatarUrl != null
                    ? NetworkImage(application.candidateAvatarUrl!)
                    : null,
                child:
                    isAnonymousScreening ||
                        application.candidateAvatarUrl == null
                    ? Text(
                        initial,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.primary),
                      )
                    : null,
              ),
              const SizedBox(width: uiSpacing12),
              Expanded(
                child: Text(
                  displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: uiSpacing8),
              Icon(
                Icons.drag_indicator_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
          if (displayEmail.trim().isNotEmpty) ...[
            const SizedBox(height: uiSpacing8),
            Text(
              displayEmail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: uiSpacing8),
            Wrap(spacing: uiSpacing8, runSpacing: uiSpacing4, children: tags),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTags({
    required BuildContext context,
    required bool isAnonymousScreening,
  }) {
    final tags = <Widget>[];
    if (application.matchScore != null) {
      final score = application.matchScore!;
      final color = score >= 80
          ? const Color(0xFF0E9F6E)
          : const Color(0xFF0F766E);
      tags.add(
        _MetaTag(
          icon: Icons.auto_awesome_outlined,
          label: 'Match ${score.toStringAsFixed(0)}%',
          color: color,
        ),
      );
    }
    if (application.hasCurriculum) {
      tags.add(
        const _MetaTag(
          icon: Icons.description_outlined,
          label: 'CV',
          color: Color(0xFF2563EB),
        ),
      );
    }
    if (application.hasCoverLetter) {
      tags.add(
        const _MetaTag(
          icon: Icons.mail_outline_rounded,
          label: 'Carta',
          color: Color(0xFF7C3AED),
        ),
      );
    }
    if (application.hasVideoCurriculum) {
      tags.add(
        _MetaTag(
          icon: Icons.ondemand_video_outlined,
          label: application.canViewVideoCurriculum
              ? 'Video visible'
              : 'Video bloqueado',
          color: application.canViewVideoCurriculum
              ? const Color(0xFF0E9F6E)
              : const Color(0xFFB45309),
        ),
      );
    }
    if (application.knockoutEvaluationNeedsAttention == true) {
      tags.add(
        const _MetaTag(
          icon: Icons.warning_amber_rounded,
          label: 'KO revisar',
          color: Color(0xFFB45309),
        ),
      );
    }
    final source = application.sourceChannel?.trim() ?? '';
    if (source.isNotEmpty && !isAnonymousScreening) {
      tags.add(
        _MetaTag(
          icon: Icons.hub_outlined,
          label: source,
          color: const Color(0xFF475569),
        ),
      );
    }
    return tags;
  }

  String _avatarInitial(String displayName) {
    final safeName = displayName.trim();
    if (safeName.isEmpty) return '?';
    return safeName.substring(0, 1).toUpperCase();
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: uiSpacing8,
        vertical: uiSpacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(uiPillRadius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: uiSpacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
