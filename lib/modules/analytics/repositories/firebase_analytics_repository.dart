import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:opti_job_app/modules/analytics/models/company_analytics.dart';
import 'package:opti_job_app/modules/analytics/models/performance_dashboard.dart';
import 'package:opti_job_app/modules/analytics/repositories/analytics_repository.dart';

class FirebaseAnalyticsRepository implements AnalyticsRepository {
  FirebaseAnalyticsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<CompanyAnalytics?> getMonthlyAnalytics(
    String companyId,
    String period,
  ) async {
    final doc = await _firestore
        .collection('analytics')
        .doc(companyId)
        .collection('monthly')
        .doc(period)
        .get();

    if (!doc.exists) return null;
    return CompanyAnalytics.fromJson(doc.data()!, id: doc.id);
  }

  @override
  Stream<List<CompanyAnalytics>> getAnalyticsHistory(
    String companyId, {
    int limit = 12,
  }) {
    return _firestore
        .collection('analytics')
        .doc(companyId)
        .collection('monthly')
        .orderBy('period', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => CompanyAnalytics.fromJson(d.data(), id: d.id))
              .toList(),
        );
  }

  @override
  Stream<PerformanceDashboard?> watchPerformanceDashboard(String companyId) {
    final docId = 'company:$companyId';
    return _firestore
        .collection('performanceDashboards')
        .doc(docId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return PerformanceDashboard.fromJson(snapshot.data()!);
        });
  }
}
