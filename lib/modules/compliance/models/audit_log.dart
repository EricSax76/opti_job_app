import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog extends Equatable {
  const AuditLog({
    required this.id,
    required this.action,
    required this.actorUid,
    required this.actorRole,
    required this.targetType,
    required this.targetId,
    this.companyId,
    this.metadata = const {},
    this.timestamp,
  });

  final String id;
  final String action;
  final String actorUid;
  final String actorRole;
  final String targetType;
  final String targetId;
  final String? companyId;
  final Map<String, dynamic> metadata;
  final DateTime? timestamp;

  @override
  List<Object?> get props => [
        id,
        action,
        actorUid,
        actorRole,
        targetType,
        targetId,
        companyId,
        metadata,
        timestamp,
      ];

  factory AuditLog.fromJson(Map<String, dynamic> json, {String? id}) {
    return AuditLog(
      id: id ?? json['id']?.toString() ?? '',
      action: json['action'] as String? ?? '',
      actorUid: json['actorUid'] as String? ?? '',
      actorRole: json['actorRole'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      companyId: json['companyId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      timestamp: _parseDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'actorUid': actorUid,
      'actorRole': actorRole,
      'targetType': targetType,
      'targetId': targetId,
      'companyId': companyId,
      'metadata': metadata,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
