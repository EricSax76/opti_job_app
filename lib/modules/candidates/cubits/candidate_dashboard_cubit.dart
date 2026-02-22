import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_dashboard_navigation.dart';

part 'candidate_dashboard_state.dart';

class CandidateDashboardCubit extends Cubit<CandidateDashboardState> {
  CandidateDashboardCubit({
    required int initialIndex,
    required this.candidateUid,
  }) : super(CandidateDashboardState.initial(initialIndex));

  final String candidateUid;

  void selectTab(int index) {
    _updateIndex(index);
  }

  void onTabChanged(int tabIndex) {
    // Determine the navigation index from the tab index.
    // This is essentially reverse mapping logic if needed, 
    // but usually keys off the nav index directly.
    // Using helper from existing code structure:
    final navIndex = candidateDashboardNavIndexForTabIndex(tabIndex);
    _updateIndex(navIndex);
  }

  void _updateIndex(int index) {
    final safeIndex = candidateDashboardClampIndex(index);
    if (state.selectedIndex == safeIndex) return;

    final path = candidateDashboardPathForIndex(
      uid: candidateUid,
      index: safeIndex,
    );

    emit(state.copyWith(
      selectedIndex: safeIndex,
      tabIndex: candidateDashboardClampTabIndex(safeIndex),
      redirectPath: path,
    ));

    // Clear redirect path asynchronously to ensure UI listeners catch the emission.
    Future.microtask(() {
      if (!isClosed) emit(state.copyWith(clearRedirectPath: true));
    });
  }
}
