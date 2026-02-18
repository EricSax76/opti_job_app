import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/companies/cubits/company_dashboard_state.dart';
import 'package:opti_job_app/modules/companies/models/company_dashboard_navigation.dart';
import 'package:opti_job_app/modules/job_offers/cubits/company_job_offers_cubit.dart';

class CompanyDashboardCubit extends Cubit<CompanyDashboardState> {
  CompanyDashboardCubit({
    required this.companyJobOffersCubit,
    required this.companyUid,
    required int initialIndex,
  }) : super(
         CompanyDashboardState(
           selectedIndex: companyDashboardClampIndex(initialIndex),
         ),
       );

  final CompanyJobOffersCubit companyJobOffersCubit;
  final String companyUid;

  void checkAndLoadCompanyOffers(String? currentCompanyUid) {
    if (currentCompanyUid != null &&
        currentCompanyUid != state.loadedCompanyUid) {
      emit(state.copyWith(loadedCompanyUid: currentCompanyUid));
      companyJobOffersCubit.start(currentCompanyUid);
    }
  }

  void selectIndex(int index) {
    final normalizedIndex = companyDashboardClampIndex(index);
    if (normalizedIndex == state.selectedIndex) return;

    final path = companyDashboardPathForIndex(
      uid: companyUid,
      index: normalizedIndex,
    );

    emit(
      state.copyWith(
        selectedIndex: normalizedIndex,
        redirectPath: path,
      ),
    );
    emit(state.copyWith(selectedIndex: normalizedIndex, redirectPath: null));
  }
}
