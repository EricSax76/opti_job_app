import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:opti_job_app/modules/job_offers/models/job_offer.dart';
import 'package:opti_job_app/modules/job_offers/repositories/job_offer_repository.dart';

part 'company_job_offers_state.dart';

class CompanyJobOffersCubit extends Cubit<CompanyJobOffersState> {
  CompanyJobOffersCubit(this._repository)
    : super(const CompanyJobOffersState());

  final JobOfferRepository _repository;

  Future<void> loadCompanyOffers(String companyUid) async {
    emit(
      state.copyWith(status: CompanyJobOffersStatus.loading, clearError: true),
    );
    try {
      final offers = await _repository.fetchByCompanyUid(companyUid);
      emit(
        state.copyWith(status: CompanyJobOffersStatus.success, offers: offers),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CompanyJobOffersStatus.failure,
          errorMessage: 'No se pudieron cargar tus ofertas.',
        ),
      );
    }
  }
}
