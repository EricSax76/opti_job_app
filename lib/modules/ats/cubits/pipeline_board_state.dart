import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/ats/models/pipeline.dart';

sealed class PipelineBoardState extends Equatable {
  const PipelineBoardState();

  @override
  List<Object?> get props => [];
}

class PipelineBoardLoading extends PipelineBoardState {
  const PipelineBoardLoading();
}

class PipelineBoardLoaded extends PipelineBoardState {
  const PipelineBoardLoaded({
    required this.pipeline,
    required this.applications,
    this.isDragging = false,
  });

  final Pipeline pipeline;
  final List<Application> applications;
  final bool isDragging;

  PipelineBoardLoaded copyWith({
    Pipeline? pipeline,
    List<Application>? applications,
    bool? isDragging,
  }) {
    return PipelineBoardLoaded(
      pipeline: pipeline ?? this.pipeline,
      applications: applications ?? this.applications,
      isDragging: isDragging ?? this.isDragging,
    );
  }

  @override
  List<Object?> get props => [pipeline, applications, isDragging];
}

class PipelineBoardError extends PipelineBoardState {
  const PipelineBoardError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
