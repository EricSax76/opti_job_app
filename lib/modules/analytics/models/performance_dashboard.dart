import 'package:equatable/equatable.dart';

class PerformanceDashboard extends Equatable {
  const PerformanceDashboard({
    required this.key,
    required this.inpP75Ms,
    required this.inpSamples,
    required this.inpRating,
    required this.inpDegraded,
    required this.thresholdMs,
    this.updatedAt,
  });

  final String key;
  final double inpP75Ms;
  final int inpSamples;
  final String inpRating;
  final bool inpDegraded;
  final int thresholdMs;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    key,
    inpP75Ms,
    inpSamples,
    inpRating,
    inpDegraded,
    thresholdMs,
    updatedAt,
  ];

  factory PerformanceDashboard.fromJson(Map<String, dynamic> json) {
    final metrics = Map<String, dynamic>.from(
      (json['metrics'] as Map?) ?? const <String, dynamic>{},
    );
    final inp = Map<String, dynamic>.from(
      (metrics['INP'] as Map?) ?? const <String, dynamic>{},
    );
    final alerts = Map<String, dynamic>.from(
      (json['alerts'] as Map?) ?? const <String, dynamic>{},
    );
    final p75 = inp['p75'] is num ? (inp['p75'] as num).toDouble() : 0.0;
    final samples = inp['samples'] is num ? (inp['samples'] as num).toInt() : 0;
    final thresholdMs = alerts['thresholdMs'] is num
        ? (alerts['thresholdMs'] as num).toInt()
        : 200;
    final updatedRaw = json['updatedAt'];

    return PerformanceDashboard(
      key: json['key']?.toString() ?? '',
      inpP75Ms: p75,
      inpSamples: samples,
      inpRating: inp['rating']?.toString() ?? 'unknown',
      inpDegraded: alerts['inpDegraded'] as bool? ?? false,
      thresholdMs: thresholdMs,
      updatedAt: _parseDate(updatedRaw),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
