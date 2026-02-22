part of 'candidate_dashboard_cubit.dart';

class CandidateDashboardState extends Equatable {
  const CandidateDashboardState({
    required this.selectedIndex,
    required this.tabIndex,
    this.redirectPath,
  });

  factory CandidateDashboardState.initial(int initialIndex) {
    final safeIndex = candidateDashboardClampIndex(initialIndex);
    return CandidateDashboardState(
      selectedIndex: safeIndex,
      tabIndex: candidateDashboardClampTabIndex(safeIndex),
    );
  }

  final int selectedIndex;
  final int tabIndex;
  /// Path to update the browser URL with (for web).
  /// null means no redirect needed.
  final String? redirectPath;

  CandidateDashboardState copyWith({
    int? selectedIndex,
    int? tabIndex,
    String? redirectPath,
    bool clearRedirectPath = false,
  }) {
    return CandidateDashboardState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      tabIndex: tabIndex ?? this.tabIndex,
      redirectPath: clearRedirectPath ? null : (redirectPath ?? this.redirectPath),
    );
  }

  @override
  List<Object?> get props => [selectedIndex, tabIndex, redirectPath];
}
