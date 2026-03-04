import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/applications/repositories/application_repository.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_state.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class PipelineBoardCubit extends Cubit<PipelineBoardState> {
  PipelineBoardCubit({
    required this.pipelineRepository,
    required this.applicationRepository,
    required this.jobOffer,
  }) : super(const PipelineBoardLoading());

  final PipelineRepository pipelineRepository;
  final ApplicationRepository applicationRepository;
  final JobOffer jobOffer;

  Future<void> loadBoard() async {
    emit(const PipelineBoardLoading());
    try {
      final pipelineId = jobOffer.pipelineId;
      if (pipelineId == null || pipelineId.isEmpty) {
        emit(const PipelineBoardError('Esta oferta no tiene un pipeline asignado.'));
        return;
      }

      final pipeline = await pipelineRepository.getPipeline(pipelineId);
      if (pipeline == null) {
        emit(const PipelineBoardError('No se pudo encontrar el pipeline.'));
        return;
      }

      var applications = await applicationRepository.getApplicationsForJobOffer(jobOffer.id);
      
      // Auto-asignación de Stage por defecto si no lo tienen
      applications = applications.map((app) {
        if (app.pipelineStageId == null && pipeline.stages.isNotEmpty) {
           return app.copyWith(pipelineStageId: pipeline.stages.first.id);
        }
        return app;
      }).toList();

      emit(PipelineBoardLoaded(pipeline: pipeline, applications: applications));
    } catch (e) {
      emit(PipelineBoardError(e.toString()));
    }
  }

  void onDragStart() {
    if (state is PipelineBoardLoaded) {
      emit((state as PipelineBoardLoaded).copyWith(isDragging: true));
    }
  }

  void onDragEnd() {
    if (state is PipelineBoardLoaded) {
      emit((state as PipelineBoardLoaded).copyWith(isDragging: false));
    }
  }

  Future<void> moveApplication(String applicationId, String newStageId, String newStageName) async {
    if (state is! PipelineBoardLoaded) return;
    final currentState = state as PipelineBoardLoaded;

    try {
      // Optimistic update
      final newApps = currentState.applications.map((app) {
        if (app.id == applicationId) {
          return app.copyWith(pipelineStageId: newStageId, pipelineStageName: newStageName);
        }
        return app;
      }).toList();

      emit(currentState.copyWith(applications: newApps));

      // Call Cloud Function for moving application (audited API action)
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('ats-moveApplicationStage');
      await callable.call({
        'applicationId': applicationId,
        'newStageId': newStageId,
        'newStageName': newStageName,
      });
      
    } catch (e) {
      // Revert in case of error
      // Para ser rigurosos recargaríamos el board, o deshacemos
      await loadBoard();
    }
  }
}
