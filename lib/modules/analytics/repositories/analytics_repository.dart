import 'package:opti_job_app/modules/analytics/models/company_analytics.dart';
import 'package:opti_job_app/modules/analytics/models/performance_dashboard.dart';

abstract class AnalyticsRepository {
  Future<CompanyAnalytics?> getMonthlyAnalytics(
    String companyId,
    String period,
  );
  Stream<List<CompanyAnalytics>> getAnalyticsHistory(
    String companyId, {
    int limit = 12,
  });
  Stream<PerformanceDashboard?> watchPerformanceDashboard(String companyId);
}
