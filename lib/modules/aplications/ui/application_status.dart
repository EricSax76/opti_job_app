import 'package:flutter/material.dart';

String applicationStatusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Pendiente';
    case 'reviewing':
      return 'En revisión';
    case 'interview':
      return 'Entrevista';
    case 'accepted':
      return 'Aceptado';
    case 'rejected':
      return 'Rechazado';
    default:
      return status;
  }
}

Color applicationStatusColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFF64748B);
    case 'reviewing':
      return const Color(0xFF0EA5E9);
    case 'interview':
      return const Color(0xFFF59E0B);
    case 'accepted':
      return const Color(0xFF16A34A);
    case 'rejected':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF334155);
  }
}

Chip applicationStatusChip(String status) {
  final color = applicationStatusColor(status);
  return Chip(
    visualDensity: VisualDensity.compact,
    backgroundColor: color.withValues(alpha: 0.12),
    side: BorderSide(color: color.withValues(alpha: 0.25)),
    label: Text(
      applicationStatusLabel(status),
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
