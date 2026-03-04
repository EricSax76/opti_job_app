part of 'analytics_dashboard_cubit.dart';

enum AnalyticsDashboardStatus { initial, loading, empty, success, failure }

class AnalyticsDashboardState extends Equatable {
  const AnalyticsDashboardState({
    this.status = AnalyticsDashboardStatus.initial,
    this.history = const [],
    this.selectedAnalytics,
  });

  final AnalyticsDashboardStatus status;
  final List<CompanyAnalytics> history;
  final CompanyAnalytics? selectedAnalytics;

  @override
  List<Object?> get props => [status, history, selectedAnalytics];

  AnalyticsDashboardState copyWith({
    AnalyticsDashboardStatus? status,
    List<CompanyAnalytics>? history,
    CompanyAnalytics? selectedAnalytics,
  }) {
    return AnalyticsDashboardState(
      status: status ?? this.status,
      history: history ?? this.history,
      selectedAnalytics: selectedAnalytics ?? this.selectedAnalytics,
    );
  }
}
