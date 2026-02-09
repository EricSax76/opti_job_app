import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';

part 'offer_applicants_state.dart';

class OfferApplicantsCubit extends Cubit<OfferApplicantsState> {
  OfferApplicantsCubit(this._applicantsRepository)
    : super(const OfferApplicantsState());

  final ApplicantsRepository _applicantsRepository;
  final Set<String> _offersLoading = <String>{};

  Future<void> loadApplicants({
    required String offerId,
    required String companyUid,
  }) async {
    await loadApplicantsForOffers(
      offerIds: [offerId],
      companyUid: companyUid,
      force: true,
    );
  }

  Future<void> loadApplicantsForOffers({
    required Iterable<String> offerIds,
    required String companyUid,
    bool force = false,
  }) async {
    final normalizedOfferIds = offerIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedOfferIds.isEmpty) return;

    final toLoad = normalizedOfferIds
        .where((offerId) {
          if (_offersLoading.contains(offerId)) return false;
          if (force) return true;
          final status =
              state.statuses[offerId] ?? OfferApplicantsStatus.initial;
          return status == OfferApplicantsStatus.initial ||
              status == OfferApplicantsStatus.failure;
        })
        .toList(growable: false);
    if (toLoad.isEmpty) return;

    _offersLoading.addAll(toLoad);

    final loadingStatuses = Map<String, OfferApplicantsStatus>.from(
      state.statuses,
    );
    final updatedErrors = Map<String, String?>.from(state.errors);
    for (final offerId in toLoad) {
      loadingStatuses[offerId] = OfferApplicantsStatus.loading;
      updatedErrors.remove(offerId);
    }
    emit(state.copyWith(statuses: loadingStatuses, errors: updatedErrors));

    try {
      final fetchedByOffer = await _applicantsRepository
          .getApplicationsForOffers(jobOfferIds: toLoad, companyUid: companyUid)
          .timeout(const Duration(seconds: 20));

      final nextApplicants = Map<String, List<Application>>.from(
        state.applicants,
      );
      final nextStatuses = Map<String, OfferApplicantsStatus>.from(
        state.statuses,
      );
      final nextErrors = Map<String, String?>.from(state.errors);

      for (final offerId in toLoad) {
        nextApplicants[offerId] = List<Application>.unmodifiable(
          fetchedByOffer[offerId] ?? const <Application>[],
        );
        nextStatuses[offerId] = OfferApplicantsStatus.success;
        nextErrors.remove(offerId);
      }

      emit(
        state.copyWith(
          statuses: nextStatuses,
          applicants: nextApplicants,
          errors: nextErrors,
        ),
      );
    } on TimeoutException catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'OfferApplicantsCubit.loadApplicantsForOffers timeout '
          'offers=$toLoad companyUid=$companyUid error=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      final nextStatuses = Map<String, OfferApplicantsStatus>.from(
        state.statuses,
      );
      final nextErrors = Map<String, String?>.from(state.errors);
      for (final offerId in toLoad) {
        nextStatuses[offerId] = OfferApplicantsStatus.failure;
        nextErrors[offerId] = 'Tiempo de espera agotado al cargar aplicantes.';
      }
      emit(state.copyWith(statuses: nextStatuses, errors: nextErrors));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'OfferApplicantsCubit.loadApplicantsForOffers error '
          'offers=$toLoad companyUid=$companyUid error=$error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      final nextStatuses = Map<String, OfferApplicantsStatus>.from(
        state.statuses,
      );
      final nextErrors = Map<String, String?>.from(state.errors);
      for (final offerId in toLoad) {
        nextStatuses[offerId] = OfferApplicantsStatus.failure;
        nextErrors[offerId] = 'No se pudieron cargar los aplicantes.';
      }
      emit(state.copyWith(statuses: nextStatuses, errors: nextErrors));
    } finally {
      _offersLoading.removeAll(toLoad);
    }
  }

  Future<void> updateApplicationStatus({
    required String offerId,
    required String applicationId,
    required String newStatus,
    required String companyUid,
  }) async {
    final newStatuses = Map<String, OfferApplicantsStatus>.from(state.statuses)
      ..[offerId] = OfferApplicantsStatus.loading;
    emit(
      state.copyWith(
        statuses: Map<String, OfferApplicantsStatus>.from(newStatuses),
      ),
    );
    try {
      await _applicantsRepository.updateApplicationStatus(
        applicationId: applicationId,
        status: newStatus,
      );
      await loadApplicants(offerId: offerId, companyUid: companyUid);
    } catch (_) {
      final updatedStatuses = Map<String, OfferApplicantsStatus>.from(
        state.statuses,
      )..[offerId] = OfferApplicantsStatus.failure;
      final updatedErrors = Map<String, String?>.from(state.errors)
        ..[offerId] = 'No se pudo actualizar el estado.';
      emit(state.copyWith(statuses: updatedStatuses, errors: updatedErrors));
    }
  }
}
