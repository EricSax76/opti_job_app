import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/utils/callable_with_fallback.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';
import 'package:opti_job_app/modules/ats/cubits/pipeline_board_state.dart';
import 'package:opti_job_app/modules/ats/repositories/pipeline_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';

class PipelineBoardCubit extends Cubit<PipelineBoardState> {
  PipelineBoardCubit({
    required this.pipelineRepository,
    required this.applicantsRepository,
    required this.jobOffer,
    FirebaseFunctions? functions,
    FirebaseFunctions? fallbackFunctions,
  }) : _callables = CallableWithFallback(
         functions:
             functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
         fallbackFunctions: fallbackFunctions ?? FirebaseFunctions.instance,
       ),
       super(const PipelineBoardLoading());

  final PipelineRepository pipelineRepository;
  final ApplicantsRepository applicantsRepository;
  final JobOffer jobOffer;
  final CallableWithFallback _callables;

  Future<void> loadBoard() async {
    emit(const PipelineBoardLoading());
    try {
      final pipelineId = jobOffer.pipelineId?.trim();
      if (pipelineId == null || pipelineId.isEmpty) {
        emit(
          const PipelineBoardError(
            'Esta oferta no tiene un pipeline asignado.',
          ),
        );
        return;
      }

      final pipeline = await pipelineRepository.getPipeline(pipelineId);
      if (pipeline == null) {
        emit(const PipelineBoardError('No se pudo encontrar el pipeline.'));
        return;
      }

      final companyUid = (jobOffer.companyUid ?? '').trim();
      var applications = await applicantsRepository.getApplicationsForOffer(
        jobOfferId: jobOffer.id,
        companyUid: companyUid,
      );

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

  Future<void> moveApplication(
    String applicationId,
    String newStageId,
    String newStageName,
  ) async {
    if (state is! PipelineBoardLoaded) return;
    final currentState = state as PipelineBoardLoaded;

    try {
      // Optimistic update
      final newApps = currentState.applications.map((app) {
        if (app.id == applicationId) {
          return app.copyWith(
            pipelineStageId: newStageId,
            pipelineStageName: newStageName,
          );
        }
        return app;
      }).toList();

      emit(currentState.copyWith(applications: newApps));

      await _callMoveStageWithFallback(
        applicationId: applicationId,
        newStageId: newStageId,
        newStageName: newStageName,
      );
    } catch (e) {
      // Revert in case of error
      // Para ser rigurosos recargaríamos el board, o deshacemos
      await loadBoard();
    }
  }

  Future<void> _callMoveStageWithFallback({
    required String applicationId,
    required String newStageId,
    required String newStageName,
  }) async {
    final payload = <String, String>{
      'applicationId': applicationId,
      'newStageId': newStageId,
      'newStageName': newStageName,
    };

    await _callables.callVoid(name: 'moveApplicationStage', payload: payload);
  }
}
