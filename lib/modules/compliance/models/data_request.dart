import 'package:equatable/equatable.dart';

enum DataRequestType {
  access,
  rectification,
  deletion,
  limitation,
  portability,
  opposition;

  static DataRequestType fromString(String value) {
    return DataRequestType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DataRequestType.access,
    );
  }
}

enum DataRequestStatus {
  pending,
  processing,
  completed,
  denied;

  static DataRequestStatus fromString(String value) {
    return DataRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DataRequestStatus.pending,
    );
  }
}

class DataRequest extends Equatable {
  const DataRequest({
    required this.id,
    required this.candidateUid,
    required this.type,
    this.status = DataRequestStatus.pending,
    required this.description,
    this.response,
    this.processedBy,
    this.createdAt,
    this.processedAt,
    this.dueAt,
  });

  final String id;
  final String candidateUid;
  final DataRequestType type;
  final DataRequestStatus status;
  final String description;
  final String? response;
  final String? processedBy;
  final DateTime? createdAt;
  final DateTime? processedAt;
  final DateTime? dueAt;

  @override
  List<Object?> get props => [
        id,
        candidateUid,
        type,
        status,
        description,
        response,
        processedBy,
        createdAt,
        processedAt,
        dueAt,
      ];

  factory DataRequest.fromJson(Map<String, dynamic> json, {String? id}) {
    return DataRequest(
      id: id ?? json['id']?.toString() ?? '',
      candidateUid: json['candidateUid'] as String? ?? '',
      type: DataRequestType.fromString(json['type'] as String? ?? 'access'),
      status: DataRequestStatus.fromString(json['status'] as String? ?? 'pending'),
      description: json['description'] as String? ?? '',
      response: json['response'] as String?,
      processedBy: json['processedBy'] as String?,
      createdAt: _parseDate(json['createdAt']),
      processedAt: _parseDate(json['processedAt']),
      dueAt: _parseDate(json['dueAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateUid': candidateUid,
      'type': type.name,
      'status': status.name,
      'description': description,
      'response': response,
      'processedBy': processedBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (dueAt != null) 'dueAt': dueAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
