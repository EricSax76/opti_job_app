import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/applications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/applications/models/application.dart';
import 'package:opti_job_app/modules/applications/ui/application_status.dart';
import 'package:opti_job_app/modules/interviews/repositories/interview_repository.dart';

class ApplicantTile extends StatelessWidget {
  const ApplicantTile({
    super.key,
    required this.application,
    required this.offerId,
    required this.companyUid,
  });

  final Application application;
  final String offerId;
  final String companyUid;

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
    subtitleParts.add('Estado: ${applicationStatusLabel(application.status)}');
    final applicationId = application.id;

    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(uiTileRadius),
        border: Border.all(color: border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: application.candidateUid.trim().isEmpty
            ? null
            : () => context.push(
                '/company/offers/$offerId/applicants/${application.candidateUid}/cv',
              ),
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
        trailing: applicationId == null
            ? null
            : PopupMenuButton<String>(
                tooltip: 'Actualizar estado',
                onSelected: (value) async {
                  if (value == 'interview') {
                    // Confirm dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Iniciar entrevista'),
                        content: const Text(
                          'Esto creará una sala de chat con el candidato. ¿Continuar?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Iniciar'),
                          ),
                        ],
                      ),
                    );

                    if (!context.mounted) return;

                    if (confirm == true) {
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Iniciando entrevista...'),
                          ),
                        );
                        final repo = context.read<InterviewRepository>();
                        final interviewId = await repo.startInterview(
                          applicationId,
                        );

                        if (context.mounted) {
                          context.pushNamed(
                            'interview-chat',
                            pathParameters: {'id': interviewId},
                          );
                        }
                      } on FirebaseFunctionsException catch (e) {
                        if (context.mounted) {
                          final message = e.message?.trim().isNotEmpty == true
                              ? e.message!
                              : 'No se pudo iniciar la entrevista.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error (${e.code}): $message'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  } else {
                    context
                        .read<OfferApplicantsCubit>()
                        .updateApplicationStatus(
                          offerId: offerId,
                          applicationId: applicationId,
                          newStatus: value,
                          companyUid: companyUid,
                        );
                  }
                },
                itemBuilder: (context) {
                  return _applicationStatuses.map((status) {
                    final isSelected = status == application.status;
                    return PopupMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          Text(applicationStatusLabel(status)),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Chip(
                  label: Text(applicationStatusLabel(application.status)),
                  side: BorderSide(color: border),
                  backgroundColor: colorScheme.surface,
                  labelStyle: TextStyle(color: ink),
                ),
              ),
      ),
    );
  }
}

const _applicationStatuses = [
  'submitted',
  'reviewing',
  'interview',
  'accepted',
  'rejected',
];

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
