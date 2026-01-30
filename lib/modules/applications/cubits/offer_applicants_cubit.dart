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
      final newApplicants = Map<String, List<Application>>.from(state.applicants)
        ..[offerId] = applicants;
      newStatuses[offerId] = OfferApplicantsStatus.success;
      emit(
        state.copyWith(
          statuses: Map<String, OfferApplicantsStatus>.from(newStatuses),
          applicants: newApplicants,
          errors: newErrors,
        ),
      );
    } on TimeoutException catch (error, stackTrace) {
      print(
        'OfferApplicantsCubit.loadApplicants timeout '
        'offerId=$offerId companyUid=$companyUid error=$error\n$stackTrace',
      );
      newStatuses[offerId] = OfferApplicantsStatus.failure;
      newErrors[offerId] = 'Tiempo de espera agotado al cargar aplicantes.';
      emit(
        state.copyWith(
          statuses: Map<String, OfferApplicantsStatus>.from(newStatuses),
          errors: Map<String, String?>.from(newErrors),
        ),
      );
    } catch (error, stackTrace) {
      print(
        'OfferApplicantsCubit.loadApplicants error '
        'offerId=$offerId companyUid=$companyUid error=$error\n$stackTrace',
      );
      newStatuses[offerId] = OfferApplicantsStatus.failure;
      newErrors[offerId] = 'No se pudieron cargar los aplicantes.';
      emit(
        state.copyWith(
          statuses: Map<String, OfferApplicantsStatus>.from(newStatuses),
          errors: Map<String, String?>.from(newErrors),
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
      newStatuses[offerId] = OfferApplicantsStatus.failure;
      final newErrors = Map<String, String?>.from(state.errors)
        ..[offerId] = 'No se pudo actualizar el estado.';
      emit(
        state.copyWith(
          statuses: Map<String, OfferApplicantsStatus>.from(newStatuses),
          errors: newErrors,
        ),
      );
    }
  }
}
