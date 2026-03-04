import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/features/ai/models/ai_service.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer_service.dart';

enum JobOfferFormStatus { idle, submitting, success, failure }

class JobOfferFormState {
  const JobOfferFormState({
    this.status = JobOfferFormStatus.idle,
    this.message,
  });

  final JobOfferFormStatus status;
  final String? message;

  JobOfferFormState copyWith({
    JobOfferFormStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return JobOfferFormState(
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class JobOfferFormCubit extends Cubit<JobOfferFormState> {
  JobOfferFormCubit(this._repository, this._aiService) : super(const JobOfferFormState());

  final JobOfferRepository _repository;
  final AiService _aiService;

  Future<void> submit(
    JobOfferPayload payload, {
    String? pipelineId,
    List<dynamic>? pipelineStages,
    List<dynamic>? knockoutQuestions,
  }) async {
    emit(
      state.copyWith(status: JobOfferFormStatus.submitting, clearMessage: true),
    );
    try {
      final biasCheckResult = await _aiService.checkJobOfferBias(
        title: payload.title,
        description: payload.description,
      );

      final compliancePayload = JobOfferPayload(
        title: payload.title,
        description: payload.description,
        location: payload.location,
        provinceId: payload.provinceId,
        provinceName: payload.provinceName,
        municipalityId: payload.municipalityId,
        municipalityName: payload.municipalityName,
        companyId: payload.companyId,
        companyUid: payload.companyUid,
        companyName: payload.companyName,
        companyAvatarUrl: payload.companyAvatarUrl,
        salaryMin: payload.salaryMin,
        salaryMax: payload.salaryMax,
        salaryCurrency: payload.salaryCurrency,
        salaryPeriod: payload.salaryPeriod,
        education: payload.education,
        jobCategory: payload.jobCategory,
        workSchedule: payload.workSchedule,
        contractType: payload.contractType,
        jobType: payload.jobType,
        keyIndicators: payload.keyIndicators,
        pipelineId: pipelineId,
        pipelineStages: pipelineStages,
        knockoutQuestions: knockoutQuestions,
        languageCheckResult: biasCheckResult,
      );

      await _repository.create(compliancePayload);
      emit(
        state.copyWith(
          status: JobOfferFormStatus.success,
          message: 'Oferta publicada con éxito.',
        ),
      );
      // Do not reset to idle immediately; let UI handle navigation or reset.
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOfferFormStatus.failure,
          message: 'Error al publicar la oferta. Intenta nuevamente.',
        ),
      );
    }
  }
}
