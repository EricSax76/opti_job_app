import 'package:flutter/material.dart';

String applicationStatusLabel(String status) {
  switch (status) {
    case 'submitted':
    case 'pending': // Legacy support
      return 'Postulado'; // changed from "Pendiente" to "Postulado" for "submitted"
    case 'reviewing':
      return 'En revisión';
    case 'interview':
      return 'Entrevista';
    case 'accepted':
      return 'Aceptado';
    case 'rejected':
      return 'Rechazado';
    case 'withdrawn':
      return 'Retirado';
    default:
      return status;
  }
}

Color applicationStatusColor(String status) {
  switch (status) {
    case 'submitted':
    case 'pending': // Legacy support
      return const Color(0xFF64748B);
    case 'reviewing':
      return const Color(0xFF0EA5E9);
    case 'interview':
      return const Color(0xFFF59E0B);
    case 'accepted':
      return const Color(0xFF16A34A);
    case 'rejected':
      return const Color(0xFFDC2626);
    case 'withdrawn':
      return const Color(0xFF94A3B8);
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
