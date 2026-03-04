import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/ats/models/pipeline.dart';
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
  PipelineTemplateCubit({
    required this.pipelineRepository,
  }) : super(PipelineTemplateInitial());

  final PipelineRepository pipelineRepository;

  Future<void> loadPipelines(String companyId) async {
    emit(PipelineTemplateLoading());
    try {
      final templates = await pipelineRepository.getTemplatePipelines();
      final companyPipelines = await pipelineRepository.getCompanyPipelines(companyId);
      
      emit(PipelineTemplateLoaded(
        templates: templates,
        companyPipelines: companyPipelines,
        selectedPipelineId: companyPipelines.isNotEmpty 
            ? companyPipelines.first.id 
            : (templates.isNotEmpty ? templates.first.id : null),
      ));
    } catch (e) {
      emit(PipelineTemplateError(e.toString()));
    }
  }

  void selectPipeline(String pipelineId) {
    if (state is PipelineTemplateLoaded) {
      emit((state as PipelineTemplateLoaded).copyWith(selectedPipelineId: pipelineId));
    }
  }
}
