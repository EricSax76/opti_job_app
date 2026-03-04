import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/analytics/models/company_analytics.dart';
import 'package:opti_job_app/modules/analytics/models/performance_dashboard.dart';
import 'package:opti_job_app/modules/analytics/repositories/analytics_repository.dart';

part 'analytics_dashboard_state.dart';

class AnalyticsDashboardCubit extends Cubit<AnalyticsDashboardState> {
  AnalyticsDashboardCubit({required AnalyticsRepository repository})
    : _repository = repository,
      super(const AnalyticsDashboardState());

  final AnalyticsRepository _repository;
  StreamSubscription? _subscription;
  StreamSubscription? _performanceSubscription;

  void loadDashboard(String companyId) {
    emit(state.copyWith(status: AnalyticsDashboardStatus.loading));

    _subscription?.cancel();
    _subscription = _repository
        .getAnalyticsHistory(companyId)
        .listen(
          (history) {
            if (history.isEmpty) {
              emit(state.copyWith(status: AnalyticsDashboardStatus.empty));
            } else {
              emit(
                state.copyWith(
                  status: AnalyticsDashboardStatus.success,
                  history: history,
                  selectedAnalytics: history.first,
                ),
              );
            }
          },
          onError: (e) {
            emit(state.copyWith(status: AnalyticsDashboardStatus.failure));
          },
        );

    _performanceSubscription?.cancel();
    _performanceSubscription = _repository
        .watchPerformanceDashboard(companyId)
        .listen(
          (dashboard) => emit(state.copyWith(performanceDashboard: dashboard)),
          onError: (_) {},
        );
  }

  void selectPeriod(CompanyAnalytics analytics) {
    emit(state.copyWith(selectedAnalytics: analytics));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _performanceSubscription?.cancel();
    return super.close();
  }
}
