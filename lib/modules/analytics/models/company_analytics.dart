import 'package:equatable/equatable.dart';

class CompanyAnalytics extends Equatable {
  const CompanyAnalytics({
    required this.id,
    required this.companyId,
    required this.period,
    required this.metrics,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String period; // YYYY-MM
  final Map<String, dynamic> metrics;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, companyId, period, metrics, updatedAt];

  factory CompanyAnalytics.fromJson(Map<String, dynamic> json, {String? id}) {
    return CompanyAnalytics(
      id: id ?? json['id']?.toString() ?? '',
      companyId: json['companyId'] as String? ?? '',
      period: json['period'] as String? ?? '',
      metrics: json['metrics'] as Map<String, dynamic>? ?? const {},
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'period': period,
      'metrics': metrics,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
