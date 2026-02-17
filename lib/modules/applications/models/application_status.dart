import 'package:flutter/material.dart';

enum ApplicationStatus {
  submitted,
  pending, // Legacy support, treats same as submitted
  reviewing,
  interview,
  accepted,
  rejected,
  withdrawn,
  unknown;

  static ApplicationStatus fromString(String? status) {
    if (status == null) return ApplicationStatus.unknown;
    try {
      return ApplicationStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.trim().toLowerCase(),
        orElse: () => ApplicationStatus.unknown,
      );
    } catch (_) {
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
        return 'Entrevista';
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
        return const Color(0xFFF59E0B);
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
