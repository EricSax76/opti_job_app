import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';

bool isDataRequestOverdue(DataRequest request, {DateTime? now}) {
  if (request.status == DataRequestStatus.completed ||
      request.status == DataRequestStatus.denied) {
    return false;
  }

  final dueAt = request.dueAt;
  if (dueAt == null) return false;
  return dueAt.isBefore(now ?? DateTime.now());
}

Color dataRequestStatusColor(DataRequestStatus status, ColorScheme scheme) {
  return switch (status) {
    DataRequestStatus.processing => scheme.primary,
    DataRequestStatus.completed => scheme.tertiary,
    DataRequestStatus.denied => scheme.error,
    _ => scheme.outline,
  };
}

String shortUid(String uid, {int visibleChars = 8}) {
  final normalized = uid.trim();
  final limit = visibleChars < 1 ? 1 : visibleChars;
  if (normalized.length <= limit + 2) return normalized;
  return '${normalized.substring(0, limit)}...';
}

String salaryGenderLabel(String gender) {
  return switch (gender) {
    'male' => 'Hombre',
    'female' => 'Mujer',
    'non_binary' => 'No binario',
    _ => gender,
  };
}

class ComplianceOpsSummaryViewData {
  const ComplianceOpsSummaryViewData({
    required this.invocations,
    required this.successes,
    required this.errors,
    required this.avgLatencyMs,
    required this.completedCount,
    required this.completedWithinCount,
    required this.completedOutsideCount,
    required this.slaRate,
    required this.hasErrors,
    required this.hasSlaBreaches,
    required this.hasOpenOverdue,
  });

  final int invocations;
  final int successes;
  final int errors;
  final int? avgLatencyMs;
  final int completedCount;
  final int completedWithinCount;
  final int completedOutsideCount;
  final double? slaRate;
  final bool hasErrors;
  final bool hasSlaBreaches;
  final bool hasOpenOverdue;

  bool get hasAlert => hasErrors || hasSlaBreaches || hasOpenOverdue;

  String get alertsLabel {
    final labels = <String>[];
    if (hasErrors) labels.add('errores de proceso');
    if (hasSlaBreaches) labels.add('incumplimientos SLA');
    if (hasOpenOverdue) labels.add('solicitudes vencidas abiertas');
    if (labels.isEmpty) return 'ninguna';
    return labels.join(' · ');
  }

  factory ComplianceOpsSummaryViewData.fromPayload(
    Map<String, dynamic> payload, {
    required int overdueOpenCount,
  }) {
    final operations = _asMap(payload['operations']);
    final processStats = _asMap(operations['processDataRequest']);
    final sla = _asMap(payload['sla']);
    final alerts = _asMap(payload['alerts']);

    final invocations = _asInt(processStats['invocations']);
    final successes = _asInt(processStats['successCount']);
    final errors = _asInt(processStats['errorCount']);
    final totalLatencyMs = _asInt(processStats['totalLatencyMs']);
    final avgLatencyMs = invocations > 0
        ? (totalLatencyMs / invocations).round()
        : null;

    final completedCount = _asInt(sla['completedCount']);
    final completedWithinCount = _asInt(sla['completedWithinCount']);
    final completedOutsideCount = _asInt(sla['completedOutsideCount']);
    final slaRate = completedCount > 0
        ? (completedWithinCount / completedCount) * 100
        : null;

    final hasErrors = _asBool(alerts['hasErrors']) || errors > 0;
    final hasSlaBreaches =
        _asBool(alerts['hasSlaBreaches']) || completedOutsideCount > 0;

    return ComplianceOpsSummaryViewData(
      invocations: invocations,
      successes: successes,
      errors: errors,
      avgLatencyMs: avgLatencyMs,
      completedCount: completedCount,
      completedWithinCount: completedWithinCount,
      completedOutsideCount: completedOutsideCount,
      slaRate: slaRate,
      hasErrors: hasErrors,
      hasSlaBreaches: hasSlaBreaches,
      hasOpenOverdue: overdueOpenCount > 0,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}

class SalaryBenchmarkRecord {
  const SalaryBenchmarkRecord({
    required this.roleKey,
    required this.roleLabel,
    required this.gender,
    required this.averageSalary,
    required this.sampleSize,
    required this.source,
    required this.updatedAt,
  });

  final String roleKey;
  final String roleLabel;
  final String gender;
  final double averageSalary;
  final int sampleSize;
  final String source;
  final DateTime updatedAt;

  factory SalaryBenchmarkRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SalaryBenchmarkRecord(
      roleKey: _asString(data['roleKey']),
      roleLabel: _asString(data['roleLabel']),
      gender: _asString(data['gender']),
      averageSalary: _asDouble(data['averageSalary']) ?? 0,
      sampleSize: _asInt(data['sampleSize']) ?? 0,
      source: _asString(data['source'], fallback: '-'),
      updatedAt:
          _asDateTime(data['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
