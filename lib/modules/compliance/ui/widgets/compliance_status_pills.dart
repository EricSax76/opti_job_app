import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opti_job_app/core/widgets/info_pill.dart';
import 'package:opti_job_app/modules/compliance/logic/consent_management_logic.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';

class ConsentStatusIndicator extends StatelessWidget {
  const ConsentStatusIndicator({super.key, required this.granted});

  final bool granted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = granted ? scheme.tertiary : scheme.error;
    return InfoPill(
      label: granted ? 'ACTIVO' : 'REVOCADO/EXPIRADO',
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color,
    );
  }
}

class DataRequestStatusIndicator extends StatelessWidget {
  const DataRequestStatusIndicator({super.key, required this.status});

  final DataRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = dataRequestStatusColor(status, Theme.of(context).colorScheme);
    return InfoPill(
      label: status.name.toUpperCase(),
      backgroundColor: color.withValues(alpha: 0.1),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color,
    );
  }
}

class DataRequestSlaPill extends StatelessWidget {
  const DataRequestSlaPill({super.key, required this.request, this.now});

  final DataRequest request;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final dueAt = request.dueAt;
    if (dueAt == null) {
      return const InfoPill(label: 'SIN SLA');
    }

    final scheme = Theme.of(context).colorScheme;
    final isOverdue = isDataRequestOverdue(request, now: now);
    final color = isOverdue ? scheme.error : scheme.primary;
    final label = isOverdue
        ? 'Vencida ${DateFormat('d MMM yyyy').format(dueAt)}'
        : 'Límite ${DateFormat('d MMM yyyy').format(dueAt)}';

    return InfoPill(
      label: label,
      backgroundColor: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.25),
      textColor: color,
    );
  }
}
