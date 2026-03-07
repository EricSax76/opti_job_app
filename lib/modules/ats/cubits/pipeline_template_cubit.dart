import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/ats/models/pipeline.dart';
import 'package:opti_job_app/modules/ats/models/pipeline_stage.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';

sealed class PipelineTemplateState extends Equatable {
  const PipelineTemplateState();

  @override
  List<Object?> get props => [];
}

class PipelineTemplateInitial extends PipelineTemplateState {}

class PipelineTemplateLoading extends PipelineTemplateState {}

class PipelineTemplateLoaded extends PipelineTemplateState {
  const PipelineTemplateLoaded({
    required this.templates,
    required this.companyPipelines,
    this.selectedPipelineId,
  });

  final List<Pipeline> templates;
  final List<Pipeline> companyPipelines;
  final String? selectedPipelineId;

  PipelineTemplateLoaded copyWith({
    List<Pipeline>? templates,
    List<Pipeline>? companyPipelines,
    String? selectedPipelineId,
  }) {
    return PipelineTemplateLoaded(
      templates: templates ?? this.templates,
      companyPipelines: companyPipelines ?? this.companyPipelines,
      selectedPipelineId: selectedPipelineId ?? this.selectedPipelineId,
    );
  }

  @override
  List<Object?> get props => [templates, companyPipelines, selectedPipelineId];
}

class PipelineTemplateError extends PipelineTemplateState {
  const PipelineTemplateError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class PipelineTemplateCubit extends Cubit<PipelineTemplateState> {
  PipelineTemplateCubit({required this.pipelineRepository})
    : super(PipelineTemplateInitial());

  final PipelineRepository pipelineRepository;

  Future<void> loadPipelines(String companyId) async {
    emit(PipelineTemplateLoading());
    try {
      final normalizedCompanyId = companyId.trim();
      final templates = await pipelineRepository.getTemplatePipelines();
      var companyPipelines = normalizedCompanyId.isEmpty
          ? <Pipeline>[]
          : await pipelineRepository.getCompanyPipelines(normalizedCompanyId);

      if (templates.isEmpty &&
          companyPipelines.isEmpty &&
          normalizedCompanyId.isNotEmpty) {
        await _createDefaultCompanyPipeline(normalizedCompanyId);
        companyPipelines = await pipelineRepository.getCompanyPipelines(
          normalizedCompanyId,
        );
      }

      emit(
        PipelineTemplateLoaded(
          templates: templates,
          companyPipelines: companyPipelines,
          selectedPipelineId: companyPipelines.isNotEmpty
              ? companyPipelines.first.id
              : (templates.isNotEmpty ? templates.first.id : null),
        ),
      );
    } catch (e) {
      emit(PipelineTemplateError(e.toString()));
    }
  }

  void selectPipeline(String pipelineId) {
    if (state is PipelineTemplateLoaded) {
      emit(
        (state as PipelineTemplateLoaded).copyWith(
          selectedPipelineId: pipelineId,
        ),
      );
    }
  }

  Future<void> _createDefaultCompanyPipeline(String companyId) async {
    final now = DateTime.now();
    final id = 'pipeline_${companyId}_${now.millisecondsSinceEpoch}';
    final pipeline = Pipeline(
      id: id,
      companyId: companyId,
      name: 'Pipeline estándar',
      stages: _defaultStages(),
      isTemplate: false,
      createdBy: companyId,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await pipelineRepository.createPipeline(pipeline);
    } catch (_) {
      // Keep UI resilient; caller will continue with empty state if creation fails.
    }
  }

  List<PipelineStage> _defaultStages() {
    return const [
      PipelineStage(
        id: 'stage_new',
        name: 'Nueva',
        order: 0,
        type: PipelineStageType.newStage,
      ),
      PipelineStage(
        id: 'stage_screening',
        name: 'Cribado',
        order: 1,
        type: PipelineStageType.screening,
      ),
      PipelineStage(
        id: 'stage_interview_1',
        name: 'Entrevista 1',
        order: 2,
        type: PipelineStageType.interview,
      ),
      PipelineStage(
        id: 'stage_interview_2',
        name: 'Entrevista 2',
        order: 3,
        type: PipelineStageType.interview,
      ),
      PipelineStage(
        id: 'stage_offer',
        name: 'Oferta',
        order: 4,
        type: PipelineStageType.offer,
      ),
      PipelineStage(
        id: 'stage_hired',
        name: 'Contratado',
        order: 5,
        type: PipelineStageType.hired,
      ),
      PipelineStage(
        id: 'stage_rejected',
        name: 'Descartado',
        order: 6,
        type: PipelineStageType.rejected,
      ),
    ];
  }
}
