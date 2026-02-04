import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applicants/repositories/applicants_repository.dart';

part 'offer_applicants_state.dart';

class OfferApplicantsCubit extends Cubit<OfferApplicantsState> {
  OfferApplicantsCubit(this._applicantsRepository)
    : super(const OfferApplicantsState());

  final ApplicantsRepository _applicantsRepository;

  Future<void> loadApplicants({
    required String offerId,
    required String companyUid,
  }) async {
    final newStatuses = Map<String, OfferApplicantsStatus>.from(state.statuses)
      ..[offerId] = OfferApplicantsStatus.loading;
    final newErrors = Map<String, String?>.from(state.errors)..remove(offerId);
    emit(
      state.copyWith(
        statuses: Map<String, OfferApplicantsStatus>.from(newStatuses),
        errors: Map<String, String?>.from(newErrors),
      ),
    );
    try {
      final applicants = await _applicantsRepository
          .getApplicationsForOffer(
            jobOfferId: offerId,
            companyUid: companyUid,
          )
          .timeout(const Duration(seconds: 12));
      
      final updatedApplicants =
          Map<String, List<Application>>.from(state.applicants)
            ..[offerId] = applicants;
      final updatedStatuses =
          Map<String, OfferApplicantsStatus>.from(state.statuses)
            ..[offerId] = OfferApplicantsStatus.success;
      final updatedErrors = Map<String, String?>.from(state.errors)
        ..remove(offerId);

      emit(
        state.copyWith(
          statuses: updatedStatuses,
          applicants: updatedApplicants,
          errors: updatedErrors,
        ),
      );
    } on TimeoutException catch (error, stackTrace) {
      print(
        'OfferApplicantsCubit.loadApplicants timeout '
        'offerId=$offerId companyUid=$companyUid error=$error\n$stackTrace',
      );
      final updatedStatuses =
          Map<String, OfferApplicantsStatus>.from(state.statuses)
            ..[offerId] = OfferApplicantsStatus.failure;
      final updatedErrors = Map<String, String?>.from(state.errors)
        ..[offerId] = 'Tiempo de espera agotado al cargar aplicantes.';
      emit(
        state.copyWith(
          statuses: updatedStatuses,
          errors: updatedErrors,
        ),
      );
    } catch (error, stackTrace) {
      print(
        'OfferApplicantsCubit.loadApplicants error '
        'offerId=$offerId companyUid=$companyUid error=$error\n$stackTrace',
      );
      final updatedStatuses =
          Map<String, OfferApplicantsStatus>.from(state.statuses)
            ..[offerId] = OfferApplicantsStatus.failure;
      final updatedErrors = Map<String, String?>.from(state.errors)
        ..[offerId] = 'No se pudieron cargar los aplicantes.';
      emit(
        state.copyWith(
          statuses: updatedStatuses,
          errors: updatedErrors,
        ),
      );
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

      final updatedStatuses =
          Map<String, OfferApplicantsStatus>.from(state.statuses)
            ..[offerId] = OfferApplicantsStatus.failure;
      final updatedErrors = Map<String, String?>.from(state.errors)
        ..[offerId] = 'No se pudo actualizar el estado.';
      emit(
        state.copyWith(
          statuses: updatedStatuses,
          errors: updatedErrors,
        ),
      );
    }

  }
}
