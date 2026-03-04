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
  });

  final PipelineStage stage;
  final List<Application> applications;

  @override
  Widget build(BuildContext context) {
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

        return SizedBox(
          width: 300,
          child: AppCard(
            margin: const EdgeInsets.only(right: uiSpacing16),
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            borderRadius: uiTileRadius,
            backgroundColor: isHovering
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
                : Theme.of(context).cardColor,
            borderColor: Theme.of(context).colorScheme.outlineVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(uiSpacing16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stage.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InfoPill(
                        icon: Icons.people_outline,
                        label: '${applications.length}',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(uiSpacing12),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      final app = applications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: uiSpacing12),
                        child: PipelineCandidateCard(application: app),
                      );
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
}
