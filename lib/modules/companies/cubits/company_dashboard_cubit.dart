import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/companies/cubits/company_dashboard_state.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';

class CompanyDashboardCubit extends Cubit<CompanyDashboardState> {
  CompanyDashboardCubit({
    required this.companyJobOffersCubit,
  }) : super(const CompanyDashboardState());

  final CompanyJobOffersCubit companyJobOffersCubit;

  void checkAndLoadCompanyOffers(String? currentCompanyUid) {
    if (currentCompanyUid != null &&
        currentCompanyUid != state.loadedCompanyUid) {
      emit(state.copyWith(loadedCompanyUid: currentCompanyUid));
      companyJobOffersCubit.loadCompanyOffers(currentCompanyUid);
    }
  }
}
