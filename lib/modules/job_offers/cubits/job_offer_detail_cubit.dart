import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';
import 'package:opti_job_app/modules/applications/logic/application_service.dart';
import 'package:opti_job_app/features/ai/repositories/ai_repository.dart';
import 'package:opti_job_app/modules/curriculum/repositories/curriculum_repository.dart';
import 'package:opti_job_app/modules/job_offers/logic/job_offer_match_logic.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

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
    required ProfileRepository profileRepository,
    String? sourceChannel,
  }) : _curriculumRepository = curriculumRepository,
       _aiRepository = aiRepository,
       _profileRepository = profileRepository,
       _sourceChannel = _normalizeSourceChannel(sourceChannel),
       super(const JobOfferDetailState());

  final JobOfferRepository _repository;
  final ApplicationService _applicationService;
  final CurriculumRepository _curriculumRepository;
  final AiRepository _aiRepository;
  final ProfileRepository _profileRepository;
  final String _sourceChannel;

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
      profileRepository: _profileRepository,
      candidateUid: normalizedUid,
      offer: offer,
    );
  }

  Future<void> apply({
    required Candidate candidate,
    required JobOffer offer,
    Map<String, dynamic>? knockoutResponses,
  }) async {
    if (!offer.isOpenForApplications) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'La oferta ya no está activa.',
        ),
      );
      return;
    }
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
      final creationResult = await _applicationService.createApplication(
        candidate: candidate,
        jobOffer: offer,
        candidateProfileId: candidate.id,
        knockoutResponses: knockoutResponses,
        sourceChannel: _sourceChannel,
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
          successMessage: creationResult.warningMessage == null
              ? '¡Te has postulado a esta oferta!'
              : '¡Te has postulado a esta oferta! ${creationResult.warningMessage}',
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: _resolveApplyErrorMessage(error),
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: _resolveApplyErrorMessage(error),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: JobOfferDetailStatus.failure,
          errorMessage: 'No se pudo enviar tu postulación. Inténtalo de nuevo.',
        ),
      );
    }
  }

  String _resolveApplyErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      final code = error.code.trim().toLowerCase();
      final message = error.message?.trim() ?? '';
      final normalized = '$code $message'.toLowerCase();

      if (normalized.contains('already applied') ||
          normalized.contains('already exists')) {
        return 'Ya te has postulado a esta oferta.';
      }
      if (normalized.contains('curriculum not found')) {
        return 'No encontramos tu currículum principal. Completa tu perfil antes de postular.';
      }
      if (normalized.contains('job offer not found')) {
        return 'La oferta ya no está disponible.';
      }
      if (normalized.contains('not active')) {
        return 'La oferta ya no está activa.';
      }
      if (normalized.contains('expired')) {
        return 'La oferta ha expirado.';
      }

      if (message.isNotEmpty) return message;
      return 'No se pudo enviar tu postulación. Inténtalo de nuevo.';
    }

    final normalized = error.toString().trim().toLowerCase();
    if (normalized.contains('application already exists') ||
        normalized.contains('already applied') ||
        normalized.contains('already exists')) {
      return 'Ya te has postulado a esta oferta.';
    }
    if (normalized.contains('curriculum not found')) {
      return 'No encontramos tu currículum principal. Completa tu perfil antes de postular.';
    }
    if (normalized.contains('job offer not found')) {
      return 'La oferta ya no está disponible.';
    }
    if (normalized.contains('not active')) {
      return 'La oferta ya no está activa.';
    }
    if (normalized.contains('expired')) {
      return 'La oferta ha expirado.';
    }

    return 'No se pudo enviar tu postulación. Inténtalo de nuevo.';
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

String _normalizeSourceChannel(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return 'platform';
  return normalized;
}
