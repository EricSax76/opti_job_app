import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_cubit.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_state.dart';
import 'package:opti_job_app/modules/ats/models/pipeline_stage.dart';
import 'package:opti_job_app/modules/ats/ui/widgets/pipeline_stage_column.dart';

class PipelineBoardScreen extends StatelessWidget {
  const PipelineBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pipeline Kanban')),
      body: BlocBuilder<PipelineBoardCubit, PipelineBoardState>(
        builder: (context, state) {
          if (state is PipelineBoardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PipelineBoardError) {
            return StateMessage(
              title: 'No se pudo cargar el pipeline',
              message: state.message,
            );
          }

          if (state is PipelineBoardLoaded) {
            final pipeline = state.pipeline;
            final applications = state.applications;
            final sortedStages = List.of(pipeline.stages)
              ..sort((a, b) => a.order.compareTo(b.order));
            if (sortedStages.isEmpty) {
              return const StateMessage(
                title: 'Pipeline sin etapas',
                message:
                    'Configura al menos una etapa para visualizar el tablero.',
              );
            }

            final applicationsByStage = _groupApplicationsByStage(
              sortedStages: sortedStages,
              applications: applications,
            );
            final totalApplications = applications.length;
            final hiredCount = _countByStageType(
              sortedStages: sortedStages,
              applicationsByStage: applicationsByStage,
              type: PipelineStageType.hired,
            );
            final rejectedCount = _countByStageType(
              sortedStages: sortedStages,
              applicationsByStage: applicationsByStage,
              type: PipelineStageType.rejected,
            );
            final inProgressCount =
                (totalApplications - hiredCount - rejectedCount).clamp(
                  0,
                  totalApplications,
                );
            final conversion = totalApplications == 0
                ? 0.0
                : (hiredCount / totalApplications) * 100;
            final isCompact =
                MediaQuery.sizeOf(context).width < uiBreakpointTablet;
            final columnWidth = isCompact ? 272.0 : 308.0;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerLowest
                        .withValues(alpha: 0.82),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      uiSpacing16,
                      uiSpacing16,
                      uiSpacing16,
                      uiSpacing12,
                    ),
                    child: _BoardSummaryCard(
                      pipelineName: pipeline.name,
                      totalStages: sortedStages.length,
                      totalApplications: totalApplications,
                      inProgressCount: inProgressCount,
                      hiredCount: hiredCount,
                      rejectedCount: rejectedCount,
                      conversion: conversion,
                      isDragging: state.isDragging,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(
                            uiSpacing16,
                            0,
                            uiSpacing16,
                            uiSpacing16,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: List.generate(sortedStages.length, (
                                index,
                              ) {
                                final stage = sortedStages[index];
                                final stageApps =
                                    applicationsByStage[stage.id] ??
                                    const <Application>[];
                                return PipelineStageColumn(
                                  stage: stage,
                                  applications: stageApps,
                                  width: columnWidth,
                                  stageNumber: index + 1,
                                  totalApplications: totalApplications,
                                );
                              }),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Map<String, List<Application>> _groupApplicationsByStage({
    required List<PipelineStage> sortedStages,
    required List<Application> applications,
  }) {
    final grouped = <String, List<Application>>{
      for (final stage in sortedStages) stage.id: <Application>[],
    };
    final fallbackStageId = sortedStages.first.id;

    for (final application in applications) {
      final stageId = application.pipelineStageId;
      if (stageId != null && grouped.containsKey(stageId)) {
        grouped[stageId]!.add(application);
      } else {
        grouped[fallbackStageId]!.add(application);
      }
    }
    return grouped;
  }

  int _countByStageType({
    required List<PipelineStage> sortedStages,
    required Map<String, List<Application>> applicationsByStage,
    required PipelineStageType type,
  }) {
    var total = 0;
    for (final stage in sortedStages.where((s) => s.type == type)) {
      total += applicationsByStage[stage.id]?.length ?? 0;
    }
    return total;
  }
}

class _BoardSummaryCard extends StatelessWidget {
  const _BoardSummaryCard({
    required this.pipelineName,
    required this.totalStages,
    required this.totalApplications,
    required this.inProgressCount,
    required this.hiredCount,
    required this.rejectedCount,
    required this.conversion,
    required this.isDragging,
  });

  final String pipelineName;
  final int totalStages;
  final int totalApplications;
  final int inProgressCount;
  final int hiredCount;
  final int rejectedCount;
  final double conversion;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(uiSpacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.42),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(uiCardRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: uiSpacing12,
            runSpacing: uiSpacing8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.view_kanban_rounded, color: colorScheme.primary),
              Text(
                pipelineName.trim().isEmpty ? 'Pipeline ATS' : pipelineName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (isDragging)
                _MetricPill(
                  icon: Icons.open_with_rounded,
                  label: 'Arrastrando candidato',
                ),
            ],
          ),
          const SizedBox(height: uiSpacing12),
          Wrap(
            spacing: uiSpacing8,
            runSpacing: uiSpacing8,
            children: [
              _MetricPill(
                icon: Icons.layers_outlined,
                label: '$totalStages etapas',
              ),
              _MetricPill(
                icon: Icons.groups_rounded,
                label: '$totalApplications candidaturas',
              ),
              _MetricPill(
                icon: Icons.pending_actions_outlined,
                label: '$inProgressCount en proceso',
              ),
              _MetricPill(
                icon: Icons.verified_user_outlined,
                label: '$hiredCount contratados',
              ),
              _MetricPill(
                icon: Icons.person_off_outlined,
                label: '$rejectedCount descartados',
              ),
              _MetricPill(
                icon: Icons.trending_up_rounded,
                label: 'Conversión ${conversion.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: uiSpacing12,
        vertical: uiSpacing8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(uiPillRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: uiSpacing8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
