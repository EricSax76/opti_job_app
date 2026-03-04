import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/inline_state_message.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_template_cubit.dart';

class PipelineTemplateSelector extends StatelessWidget {
  const PipelineTemplateSelector({super.key, required this.onPipelineSelected});

  final ValueChanged<String?> onPipelineSelected;

  @override
  Widget build(BuildContext context) {
    PipelineTemplateCubit? pipelineCubit;
    try {
      pipelineCubit = context.read<PipelineTemplateCubit>();
    } catch (_) {
      pipelineCubit = null;
    }

    if (pipelineCubit == null) {
      return const InlineStateMessage(
        icon: Icons.view_kanban_outlined,
        message: 'Pipelines no disponibles en este contexto.',
        color: uiMuted,
      );
    }

    return BlocConsumer<PipelineTemplateCubit, PipelineTemplateState>(
      bloc: pipelineCubit,
      listener: (context, state) {
        if (state is PipelineTemplateLoaded) {
          onPipelineSelected(state.selectedPipelineId);
        }
      },
      builder: (context, state) {
        if (state is PipelineTemplateLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PipelineTemplateError) {
          return InlineStateMessage(
            icon: Icons.error_outline,
            message: 'Error cargando pipelines: ${state.message}',
            color: uiError,
          );
        } else if (state is PipelineTemplateLoaded) {
          // Combinar las vistas
          final allPipelines = [...state.companyPipelines, ...state.templates];

          if (allPipelines.isEmpty) {
            return const InlineStateMessage(
              icon: Icons.view_kanban_outlined,
              message: 'No hay pipelines disponibles.',
              color: uiMuted,
            );
          }

          return DropdownButtonFormField<String>(
            initialValue: state.selectedPipelineId,
            decoration: InputDecoration(
              labelText: 'Selecciona un proceso de selección (Pipeline)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(uiFieldRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: uiSpacing16,
                vertical: uiSpacing12,
              ),
            ),
            items: allPipelines.map((pipeline) {
              return DropdownMenuItem(
                value: pipeline.id,
                child: Text(
                  '${pipeline.name} ${pipeline.isTemplate ? "(Plantilla)" : ""}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<PipelineTemplateCubit>().selectPipeline(value);
              }
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
