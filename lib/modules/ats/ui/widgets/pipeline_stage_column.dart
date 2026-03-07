import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_cubit.dart';
import 'package:opti_job_app/modules/ats/models/pipeline_stage.dart';

import 'package:opti_job_app/modules/ats/ui/widgets/pipeline_candidate_card.dart';

class PipelineStageColumn extends StatelessWidget {
  const PipelineStageColumn({
    super.key,
    required this.stage,
    required this.applications,
    required this.stageNumber,
    required this.totalApplications,
    this.width = 300,
  });

  final PipelineStage stage;
  final List<Application> applications;
  final int stageNumber;
  final int totalApplications;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stageColor = _stageColor(colorScheme);
    final stageIcon = _stageIcon();
    final occupancy = totalApplications == 0
        ? 0.0
        : applications.length / totalApplications;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        context.read<PipelineBoardCubit>().moveApplication(
          details.data,
          stage.id,
          stage.name,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: uiDurationFast,
          curve: Curves.easeOutCubic,
          width: width,
          child: AppCard(
            margin: const EdgeInsets.only(right: uiSpacing12),
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            borderRadius: uiCardRadius,
            backgroundColor: isHovering
                ? stageColor.withValues(alpha: 0.12)
                : colorScheme.surface,
            borderColor: isHovering
                ? stageColor.withValues(alpha: 0.75)
                : colorScheme.outlineVariant,
            boxShadow: isHovering ? uiShadowMd : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    uiSpacing16,
                    uiSpacing16,
                    uiSpacing16,
                    uiSpacing12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        stageColor.withValues(alpha: 0.18),
                        colorScheme.surfaceContainerLowest,
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(stageIcon, size: 16, color: stageColor),
                          ),
                          const SizedBox(width: uiSpacing8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage.name,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Etapa $stageNumber',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          InfoPill(
                            icon: Icons.people_outline,
                            label: '${applications.length}',
                            backgroundColor: stageColor.withValues(alpha: 0.12),
                            borderColor: stageColor.withValues(alpha: 0.35),
                            textColor: stageColor,
                            iconColor: stageColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: uiSpacing8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(uiPillRadius),
                        child: LinearProgressIndicator(
                          value: occupancy.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: stageColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(stageColor),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: applications.isEmpty
                      ? _EmptyStageHint(stageName: stage.name)
                      : ListView.separated(
                          padding: const EdgeInsets.all(uiSpacing12),
                          itemCount: applications.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: uiSpacing8),
                          itemBuilder: (context, index) {
                            final app = applications[index];
                            return PipelineCandidateCard(application: app);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _stageIcon() {
    return switch (stage.type) {
      PipelineStageType.newStage => Icons.flag_outlined,
      PipelineStageType.screening => Icons.fact_check_outlined,
      PipelineStageType.interview => Icons.record_voice_over_outlined,
      PipelineStageType.offer => Icons.handshake_outlined,
      PipelineStageType.hired => Icons.verified_outlined,
      PipelineStageType.rejected => Icons.person_off_outlined,
    };
  }

  Color _stageColor(ColorScheme colorScheme) {
    return switch (stage.type) {
      PipelineStageType.newStage => colorScheme.primary,
      PipelineStageType.screening => colorScheme.secondary,
      PipelineStageType.interview => colorScheme.tertiary,
      PipelineStageType.offer => const Color(0xFF1B8A5A),
      PipelineStageType.hired => const Color(0xFF0E9F6E),
      PipelineStageType.rejected => colorScheme.error,
    };
  }
}

class _EmptyStageHint extends StatelessWidget {
  const _EmptyStageHint({required this.stageName});

  final String stageName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(uiSpacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: uiSpacing8),
            Text(
              'Sin candidaturas',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: uiSpacing4),
            Text(
              'Arrastra perfiles a "$stageName".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
