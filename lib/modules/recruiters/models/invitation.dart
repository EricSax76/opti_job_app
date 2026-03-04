import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';

/// Estado de vida de una invitación.
enum InvitationStatus {
  pending,
  accepted,
  expired;

  static InvitationStatus fromString(String value) {
    return switch (value) {
      'pending' => InvitationStatus.pending,
      'accepted' => InvitationStatus.accepted,
      'expired' => InvitationStatus.expired,
      _ => InvitationStatus.expired,
    };
  }

  String toFirestoreString() {
    return switch (this) {
      InvitationStatus.pending => 'pending',
      InvitationStatus.accepted => 'accepted',
      InvitationStatus.expired => 'expired',
    };
  }
}

/// Invitación de 6 caracteres para unirse a una empresa como reclutador.
///
/// Vive en `invitations/{code}`. Caduca 72 horas tras su creación.
class Invitation extends Equatable {
  const Invitation({
    required this.code,
    required this.companyId,
    required this.role,
    this.email,
    required this.createdBy,
    this.usedBy,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Código alfanumérico de 6 caracteres (case-insensitive).
  final String code;
  final String companyId;
  final RecruiterRole role;

  /// Email opcional al que va dirigida la invitación.
  final String? email;

  /// UID del admin que creó la invitación.
  final String createdBy;

  /// UID del usuario que canjeó la invitación.
  final String? usedBy;

  final InvitationStatus status;
  final DateTime createdAt;

  /// Instante de caducidad — 72h después de `createdAt`.
  final DateTime expiresAt;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == InvitationStatus.pending && !isExpired;

  // ─── Serialización ────────────────────────────────────────────────────────

  factory Invitation.fromFirestore(Map<String, dynamic> data) {
    DateTime toDateTime(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.now();
    }

    return Invitation(
      code: data['code'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      role: RecruiterRole.fromString(data['role'] as String? ?? 'viewer'),
      email: data['email'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      usedBy: data['usedBy'] as String?,
      status: InvitationStatus.fromString(
        data['status'] as String? ?? 'expired',
      ),
      createdAt: toDateTime(data['createdAt']),
      expiresAt: toDateTime(data['expiresAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'code': code,
      'companyId': companyId,
      'role': role.toFirestoreString(),
      if (email != null) 'email': email,
      'createdBy': createdBy,
      if (usedBy != null) 'usedBy': usedBy,
      'status': status.toFirestoreString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  @override
  List<Object?> get props => [
    code,
    companyId,
    role,
    email,
    createdBy,
    usedBy,
    status,
    createdAt,
    expiresAt,
  ];
}
