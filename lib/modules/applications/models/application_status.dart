import 'package:flutter/material.dart';

enum ApplicationStatus {
  submitted,
  pending, // Legacy support, treats same as submitted
  reviewing,
  interview,
  interviewing, // Legacy/ATS state
  offered,
  acceptedPendingSignature,
  accepted,
  rejected,
  withdrawn,
  unknown;

  static ApplicationStatus fromString(String? status) {
    if (status == null) return ApplicationStatus.unknown;
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'submitted':
      case 'pending':
        return ApplicationStatus.submitted;
      case 'reviewing':
      case 'in_review':
        return ApplicationStatus.reviewing;
      case 'interview':
        return ApplicationStatus.interview;
      case 'interviewing':
        return ApplicationStatus.interviewing;
      case 'offered':
        return ApplicationStatus.offered;
      case 'accepted_pending_signature':
        return ApplicationStatus.acceptedPendingSignature;
      case 'accepted':
      case 'hired':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'withdrawn':
        return ApplicationStatus.withdrawn;
      default:
        return ApplicationStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case ApplicationStatus.submitted:
      case ApplicationStatus.pending:
        return 'Postulado';
      case ApplicationStatus.reviewing:
        return 'En revisión';
      case ApplicationStatus.interview:
      case ApplicationStatus.interviewing:
        return 'Entrevista';
      case ApplicationStatus.offered:
        return 'Oferta';
      case ApplicationStatus.acceptedPendingSignature:
        return 'Pendiente de firma';
      case ApplicationStatus.accepted:
        return 'Aceptado';
      case ApplicationStatus.rejected:
        return 'Rechazado';
      case ApplicationStatus.withdrawn:
        return 'Retirado';
      case ApplicationStatus.unknown:
        return 'Desconocido';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.submitted:
      case ApplicationStatus.pending:
        return const Color(0xFF64748B);
      case ApplicationStatus.reviewing:
        return const Color(0xFF0EA5E9);
      case ApplicationStatus.interview:
      case ApplicationStatus.interviewing:
        return const Color(0xFFF59E0B);
      case ApplicationStatus.offered:
        return const Color(0xFF7C3AED);
      case ApplicationStatus.acceptedPendingSignature:
        return const Color(0xFF2563EB);
      case ApplicationStatus.accepted:
        return const Color(0xFF16A34A);
      case ApplicationStatus.rejected:
        return const Color(0xFFDC2626);
      case ApplicationStatus.withdrawn:
        return const Color(0xFF94A3B8);
      case ApplicationStatus.unknown:
        return const Color(0xFF334155);
    }
  }
}
