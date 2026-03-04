import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

/// Estado de actividad de un reclutador en la plataforma.
enum RecruiterStatus {
  active,
  invited,
  disabled;

  static RecruiterStatus fromString(String value) {
    return switch (value) {
      'active' => RecruiterStatus.active,
      'invited' => RecruiterStatus.invited,
      'disabled' => RecruiterStatus.disabled,
      _ => RecruiterStatus.invited,
    };
  }

  String toFirestoreString() {
    return switch (this) {
      RecruiterStatus.active => 'active',
      RecruiterStatus.invited => 'invited',
      RecruiterStatus.disabled => 'disabled',
    };
  }
}

/// Representa a un miembro del equipo de reclutamiento de una empresa.
///
/// El documento vive en `recruiters/{uid}` donde `uid` es el UID de Firebase Auth.
class Recruiter extends Equatable {
  const Recruiter({
    required this.uid,
    required this.companyId,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    this.invitedBy,
    this.invitedAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String companyId;
  final String email;
  final String name;
  final RecruiterRole role;
  final RecruiterStatus status;

  /// UID del reclutador que generó la invitación (null para admins fundadores).
  final String? invitedBy;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ─── Helpers de estado ────────────────────────────────────────────────────

  bool get isAdmin => role == RecruiterRole.admin;
  bool get isActive => status == RecruiterStatus.active;

  // ─── Serialización ────────────────────────────────────────────────────────

  factory Recruiter.fromFirestore(Map<String, dynamic> data) {
    DateTime toDateTime(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.now();
    }

    DateTime? toDateTimeOpt(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return null;
    }

    return Recruiter(
      uid: data['uid'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: RecruiterRole.fromString(data['role'] as String? ?? 'viewer'),
      status: RecruiterStatus.fromString(
        data['status'] as String? ?? 'invited',
      ),
      invitedBy: data['invitedBy'] as String?,
      invitedAt: toDateTimeOpt(data['invitedAt']),
      acceptedAt: toDateTimeOpt(data['acceptedAt']),
      createdAt: toDateTime(data['createdAt']),
      updatedAt: toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'uid': uid,
      'companyId': companyId,
      'email': email,
      'name': name,
      'role': role.toFirestoreString(),
      'status': status.toFirestoreString(),
      if (invitedBy != null) 'invitedBy': invitedBy,
      if (invitedAt != null) 'invitedAt': Timestamp.fromDate(invitedAt!),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Recruiter copyWith({
    String? uid,
    String? companyId,
    String? email,
    String? name,
    RecruiterRole? role,
    RecruiterStatus? status,
    String? invitedBy,
    DateTime? invitedAt,
    DateTime? acceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recruiter(
      uid: uid ?? this.uid,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedAt: invitedAt ?? this.invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    companyId,
    email,
    name,
    role,
    status,
    invitedBy,
    invitedAt,
    acceptedAt,
    createdAt,
    updatedAt,
  ];
}
