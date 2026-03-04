import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/widgets/state_message.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_cubit.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_state.dart';
import 'package:opti_job_app/modules/ats/ui/widgets/pipeline_stage_column.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

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

            // Ordenamos los stages según order
            final sortedStages = List.of(pipeline.stages)
              ..sort((a, b) => a.order.compareTo(b.order));

            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(uiSpacing16),
                itemCount: sortedStages.length,
                itemBuilder: (context, index) {
                  final stage = sortedStages[index];
                  // Filtramos postulaciones de este stage
                  final stageApps = applications
                      .where((a) => a.pipelineStageId == stage.id)
                      .toList();

                  return PipelineStageColumn(
                    stage: stage,
                    applications: stageApps,
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
