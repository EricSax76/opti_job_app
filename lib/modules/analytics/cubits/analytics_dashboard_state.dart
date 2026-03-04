part of 'analytics_dashboard_cubit.dart';

enum AnalyticsDashboardStatus { initial, loading, empty, success, failure }

class AnalyticsDashboardState extends Equatable {
  const AnalyticsDashboardState({
    this.status = AnalyticsDashboardStatus.initial,
    this.history = const [],
    this.selectedAnalytics,
    this.performanceDashboard,
  });

  final AnalyticsDashboardStatus status;
  final List<CompanyAnalytics> history;
  final CompanyAnalytics? selectedAnalytics;
  final PerformanceDashboard? performanceDashboard;

  @override
  List<Object?> get props => [
    status,
    history,
    selectedAnalytics,
    performanceDashboard,
  ];

  AnalyticsDashboardState copyWith({
    AnalyticsDashboardStatus? status,
    List<CompanyAnalytics>? history,
    CompanyAnalytics? selectedAnalytics,
    PerformanceDashboard? performanceDashboard,
  }) {
    return AnalyticsDashboardState(
      status: status ?? this.status,
      history: history ?? this.history,
      selectedAnalytics: selectedAnalytics ?? this.selectedAnalytics,
      performanceDashboard: performanceDashboard ?? this.performanceDashboard,
    );
  }
}
