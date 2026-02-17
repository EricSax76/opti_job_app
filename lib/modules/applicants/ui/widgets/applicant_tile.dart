import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/models/application_status.dart';
import 'package:opti_job_app/modules/applications/ui/widgets/application_status_badge.dart';

class ApplicantTile extends StatelessWidget {
  const ApplicantTile({
    super.key,
    required this.application,
    this.onTap,
    this.onStatusChanged,
    this.onStartInterview,
  });

  final Application application;
  final VoidCallback? onTap;
  final ValueChanged<String>? onStatusChanged;
  final VoidCallback? onStartInterview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    final border = colorScheme.outline;
    final avatarBg = colorScheme.primary;
    final avatarFg = colorScheme.onPrimary;

    final subtitleParts = <String>[];
    if (application.candidateEmail != null &&
        application.candidateEmail!.isNotEmpty) {
      subtitleParts.add(application.candidateEmail!);
    }
    subtitleParts.add('Estado: ${ApplicationStatus.fromString(application.status).label}');

    final canChangeStatus = onStatusChanged != null && onStartInterview != null;

    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: avatarBg,
          foregroundColor: avatarFg,
          child: Text(_initials(application)),
        ),
        title: Text(
          application.candidateName ??
              application.candidateEmail ??
              application.candidateUid,
          style: TextStyle(color: ink, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitleParts.join(' • '),
          style: TextStyle(color: muted, height: 1.35),
        ),
        trailing: !canChangeStatus
            ? null
            : PopupMenuButton<String>(
                tooltip: 'Actualizar estado',
                onSelected: (value) {
                  if (value == ApplicationStatus.interview.name) {
                    onStartInterview?.call();
                  } else {
                    onStatusChanged?.call(value);
                  }
                },
                itemBuilder: (context) {
                  return ApplicationStatus.values
                      .where((s) =>
                          s != ApplicationStatus.pending &&
                          s != ApplicationStatus.unknown &&
                          s != ApplicationStatus.withdrawn)
                      .map((status) {
                    final isSelected = status.name == application.status;
                    return PopupMenuItem<String>(
                      value: status.name,
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          Text(status.label),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: ApplicationStatusBadge.fromString(application.status),
              ),
      ),
    );
  }
}



String _initials(Application application) {
  final raw =
      (application.candidateName?.trim().isNotEmpty == true
              ? application.candidateName!
              : application.candidateEmail?.trim().isNotEmpty == true
                  ? application.candidateEmail!
                  : application.candidateUid)
          .trim();
  if (raw.isEmpty) {
    return '?';
  }
  return raw.substring(0, 1).toUpperCase();
}
