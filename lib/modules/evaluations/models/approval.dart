enum ApprovalStatus {
  pending,
  approved,
  rejected;

  static ApprovalStatus fromString(String value) {
    return ApprovalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ApprovalStatus.pending,
    );
  }
}

enum ApprovalType {
  offerApproval,
  salaryApproval;

  static ApprovalType fromString(String value) {
    return ApprovalType.values.firstWhere(
      (e) => e.name == value || e.toSnakeCase() == value,
      orElse: () => ApprovalType.offerApproval,
    );
  }

  String toSnakeCase() {
    return name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
  }
}

class Approval {
  const Approval({
    required this.id,
    required this.applicationId,
    required this.jobOfferId,
    required this.companyId,
    required this.type,
    required this.requestedBy,
    required this.approvers,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String applicationId;
  final String jobOfferId;
  final String companyId;
  final ApprovalType type;
  final String requestedBy;
  final List<Approver> approvers;
  final ApprovalStatus status;
  final DateTime? createdAt;

  factory Approval.fromFirestore(Map<String, dynamic> data) {
    final approversRaw = data['approvers'] as List<dynamic>? ?? [];
    return Approval(
      id: data['id'] as String? ?? '',
      applicationId: data['applicationId'] as String? ?? '',
      jobOfferId: data['jobOfferId'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      type: ApprovalType.fromString(data['type'] as String? ?? ''),
      requestedBy: data['requestedBy'] as String? ?? '',
      approvers: approversRaw
          .whereType<Map<String, dynamic>>()
          .map(Approver.fromFirestore)
          .toList(),
      status: ApprovalStatus.fromString(data['status'] as String? ?? ''),
      createdAt: _parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'applicationId': applicationId,
      'jobOfferId': jobOfferId,
      'companyId': companyId,
      'type': type.toSnakeCase(),
      'requestedBy': requestedBy,
      'approvers': approvers.map((a) => a.toFirestore()).toList(),
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as int) * 1000,
      );
    }
    return null;
  }
}

class Approver {
  const Approver({
    required this.uid,
    required this.name,
    required this.status,
    this.decidedAt,
    this.notes,
  });

  final String uid;
  final String name;
  final ApprovalStatus status;
  final DateTime? decidedAt;
  final String? notes;

  factory Approver.fromFirestore(Map<String, dynamic> data) {
    return Approver(
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      status: ApprovalStatus.fromString(data['status'] as String? ?? ''),
      decidedAt: _parseDate(data['decidedAt']),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'status': status.name,
      'decidedAt': decidedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as int) * 1000,
      );
    }
    return null;
  }
}
