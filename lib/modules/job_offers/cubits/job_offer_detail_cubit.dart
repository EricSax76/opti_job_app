import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

enum JobOfferDetailStatus { initial, loading, success, failure, applying }

class JobOfferDetailState {
  const JobOfferDetailState({
    this.status = JobOfferDetailStatus.initial,
    this.offer,
    this.application,
    this.errorMessage,
    this.successMessage,
    this.matchOutcome,
  });

  final JobOfferDetailStatus status;
  final JobOffer? offer;
  final Application? application;
  final String? errorMessage;
  final String? successMessage;
  final JobOfferMatchOutcome? matchOutcome;

  JobOfferDetailState copyWith({
    JobOfferDetailStatus? status,
    JobOffer? offer,
    Application? application,
    String? errorMessage,
    String? successMessage,
    JobOfferMatchOutcome? matchOutcome,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearOffer = false,
    bool clearApplication = false,
    bool clearMatchOutcome = false,
  }) {
    return JobOfferDetailState(
      status: status ?? this.status,
      offer: clearOffer ? null : offer ?? this.offer,
      application: clearApplication ? null : application ?? this.application,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
      matchOutcome: clearMatchOutcome
          ? null
          : matchOutcome ?? this.matchOutcome,
    );
  }
}

class JobOfferDetailCubit extends Cubit<JobOfferDetailState> {
  JobOfferDetailCubit(
    this._repository,
    this._applicationService, {
    required CurriculumRepository curriculumRepository,
    required AiRepository aiRepository,
  }) : _curriculumRepository = curriculumRepository,
       _aiRepository = aiRepository,
       super(const JobOfferDetailState());

  final JobOfferRepository _repository;
  final ApplicationService _applicationService;
  final CurriculumRepository _curriculumRepository;
  final AiRepository _aiRepository;

  String? _offerId;
  String? _candidateUid;

  Future<void> start(String id, {String? candidateUid}) async {
    _offerId = id;
    _candidateUid = candidateUid;
    return refresh();
  }

  Future<void> refresh() async {
    if (_offerId == null) return;
    emit(
      state.copyWith(
        status: JobOfferDetailStatus.loading,
        clearError: true,
        clearSuccess: true,
        clearOffer: true,
        clearApplication: true,
      ),
    );
    try {
      final offer = await _repository.fetchById(_offerId!);
      Application? application;
      if (_candidateUid != null && _candidateUid!.isNotEmpty) {
        try {
          application = await _applicationService
              .getApplicationForCandidateOffer(
                jobOfferId: offer.id,
                candidateUid: _candidateUid!,
              );
        } catch (_) {
          application = null;
        }
      }
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.success,
          offer: offer,
          application: application,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'No se pudo cargar la oferta seleccionada.',
        ),
      );
    }
  }

  void retry() => unawaited(refresh());

  Future<JobOfferMatchOutcome> evaluateFitForApplication({
    required String candidateUid,
    required JobOffer offer,
  }) {
    final normalizedUid = candidateUid.trim();
    if (normalizedUid.isEmpty) {
      return Future.value(
        const JobOfferMatchFailure(
          'No se pudo identificar tu perfil para evaluar la oferta.',
        ),
      );
    }
    return JobOfferMatchLogic.computeMatch(
      curriculumRepository: _curriculumRepository,
      aiRepository: _aiRepository,
      candidateUid: normalizedUid,
      offer: offer,
    );
  }

  Future<void> apply({
    required Candidate candidate,
    required JobOffer offer,
  }) async {
    if (state.application != null) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'Ya te has postulado a esta oferta.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: JobOfferDetailStatus.applying,
        clearError: true,
        clearSuccess: true,
      ),
    );
    try {
      await _applicationService.createApplication(
        candidate: candidate,
        jobOffer: offer,
        candidateProfileId: candidate.id,
      );
      final application = await _applicationService
          .getApplicationForCandidateOffer(
            jobOfferId: offer.id,
            candidateUid: candidate.uid,
          );
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.success,
          application: application,
          successMessage: '¡Te has postulado a esta oferta!',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'Ya te has postulado a esta oferta.',
        ),
      );
    }
  }

  Future<void> computeMatch() async {
    final offer = state.offer;
    final candidateUid = _candidateUid?.trim();
    if (offer == null || candidateUid == null || candidateUid.isEmpty) return;

    emit(state.copyWith(status: JobOfferDetailStatus.loading));

    final outcome = await evaluateFitForApplication(
      candidateUid: candidateUid,
      offer: offer,
    );

    emit(
      state.copyWith(
        status: JobOfferDetailStatus.success,
        matchOutcome: outcome,
      ),
    );
  }

  void clearMatchOutcome() {
    emit(state.copyWith(clearMatchOutcome: true));
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}
