import 'package:flutter_test/flutter_test.dart';
import 'package:opti_job_app/modules/compliance/logic/consent_management_logic.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';

void main() {
  group('ComplianceOpsSummaryViewData', () {
    test('parses payload metrics and alerts', () {
      final viewData = ComplianceOpsSummaryViewData.fromPayload({
        'operations': {
          'processDataRequest': {
            'invocations': '4',
            'successCount': 3,
            'errorCount': 1,
            'totalLatencyMs': 1200,
          },
        },
        'sla': {
          'completedCount': 2,
          'completedWithinCount': 1,
          'completedOutsideCount': 1,
        },
        'alerts': {'hasErrors': false, 'hasSlaBreaches': false},
      }, overdueOpenCount: 2);

      expect(viewData.invocations, 4);
      expect(viewData.successes, 3);
      expect(viewData.errors, 1);
      expect(viewData.avgLatencyMs, 300);
      expect(viewData.completedCount, 2);
      expect(viewData.completedWithinCount, 1);
      expect(viewData.completedOutsideCount, 1);
      expect(viewData.slaRate, 50);
      expect(viewData.hasErrors, isTrue);
      expect(viewData.hasSlaBreaches, isTrue);
      expect(viewData.hasOpenOverdue, isTrue);
      expect(viewData.hasAlert, isTrue);
      expect(
        viewData.alertsLabel,
        'errores de proceso · incumplimientos SLA · solicitudes vencidas abiertas',
      );
    });

    test('returns no alerts label when payload has no issues', () {
      final viewData = ComplianceOpsSummaryViewData.fromPayload(
        const <String, dynamic>{},
        overdueOpenCount: 0,
      );

      expect(viewData.hasAlert, isFalse);
      expect(viewData.alertsLabel, 'ninguna');
      expect(viewData.avgLatencyMs, isNull);
      expect(viewData.slaRate, isNull);
    });
  });

  group('helper logic', () {
    test('shortUid truncates long values', () {
      expect(shortUid('1234567890abcdef'), '12345678...');
      expect(shortUid('1234567'), '1234567');
    });

    test('salaryGenderLabel maps known values', () {
      expect(salaryGenderLabel('male'), 'Hombre');
      expect(salaryGenderLabel('female'), 'Mujer');
      expect(salaryGenderLabel('non_binary'), 'No binario');
      expect(salaryGenderLabel('other'), 'other');
    });

    test('isDataRequestOverdue checks due date and status', () {
      final now = DateTime(2026, 3, 10, 12);
      final overduePending = DataRequest(
        id: '1',
        candidateUid: 'candidate',
        type: DataRequestType.access,
        status: DataRequestStatus.pending,
        description: 'desc',
        dueAt: DateTime(2026, 3, 9, 23, 59),
      );
      final overdueCompleted = DataRequest(
        id: '2',
        candidateUid: 'candidate',
        type: DataRequestType.access,
        status: DataRequestStatus.completed,
        description: 'desc',
        dueAt: DateTime(2026, 3, 9, 23, 59),
      );
      final pendingInTime = DataRequest(
        id: '3',
        candidateUid: 'candidate',
        type: DataRequestType.access,
        status: DataRequestStatus.pending,
        description: 'desc',
        dueAt: DateTime(2026, 3, 11),
      );

      expect(isDataRequestOverdue(overduePending, now: now), isTrue);
      expect(isDataRequestOverdue(overdueCompleted, now: now), isFalse);
      expect(isDataRequestOverdue(pendingInTime, now: now), isFalse);
    });
  });
}
