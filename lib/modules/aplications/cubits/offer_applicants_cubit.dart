import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/aplicants/repositories/applicants_repository.dart';

part 'offer_applicants_state.dart';

class OfferApplicantsCubit extends Cubit<OfferApplicantsState> {
  OfferApplicantsCubit(this._applicantsRepository)
    : super(const OfferApplicantsState());

  final ApplicantsRepository _applicantsRepository;

  Future<void> loadApplicants({
    required int offerId,
    required String companyUid,
  }) async {
    final newStatuses = Map<int, OfferApplicantsStatus>.from(state.statuses)
      ..[offerId] = OfferApplicantsStatus.loading;
    final newErrors = Map<int, String?>.from(state.errors)..remove(offerId);
    emit(
      state.copyWith(
        statuses: Map<int, OfferApplicantsStatus>.from(newStatuses),
        errors: Map<int, String?>.from(newErrors),
      ),
    );
    try {
      final applicants = await _applicantsRepository.getApplicationsForOffer(
        jobOfferId: offerId,
        companyUid: companyUid,
      );
      final newApplicants = Map<int, List<Application>>.from(state.applicants)
        ..[offerId] = applicants;
      newStatuses[offerId] = OfferApplicantsStatus.success;
      emit(
        state.copyWith(
          statuses: Map<int, OfferApplicantsStatus>.from(newStatuses),
          applicants: newApplicants,
          errors: newErrors,
        ),
      );
    } catch (_) {
      newStatuses[offerId] = OfferApplicantsStatus.failure;
      newErrors[offerId] = 'No se pudieron cargar los aplicantes.';
      emit(
        state.copyWith(
          statuses: Map<int, OfferApplicantsStatus>.from(newStatuses),
          errors: Map<int, String?>.from(newErrors),
        ),
      );
    }
  }

  Future<void> updateApplicationStatus({
    required int offerId,
    required String applicationId,
    required String newStatus,
    required String companyUid,
  }) async {
    final newStatuses = Map<int, OfferApplicantsStatus>.from(state.statuses)
      ..[offerId] = OfferApplicantsStatus.loading;
    emit(
      state.copyWith(
        statuses: Map<int, OfferApplicantsStatus>.from(newStatuses),
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
      final newErrors = Map<int, String?>.from(state.errors)
        ..[offerId] = 'No se pudo actualizar el estado.';
      emit(
        state.copyWith(
          statuses: Map<int, OfferApplicantsStatus>.from(newStatuses),
          errors: newErrors,
        ),
      );
    }
  }
}
