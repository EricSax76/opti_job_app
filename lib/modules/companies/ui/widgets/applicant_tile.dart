import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/application.dart';

class ApplicantTile extends StatelessWidget {
  const ApplicantTile({
    super.key,
    required this.application,
    required this.offerId,
    required this.companyUid,
  });

  final Application application;
  final int offerId;
  final String companyUid;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8FAFC);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    final subtitleParts = <String>[];
    if (application.candidateEmail != null &&
        application.candidateEmail!.isNotEmpty) {
      subtitleParts.add(application.candidateEmail!);
    }
    subtitleParts.add('Estado: ${_statusLabel(application.status)}');

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          child: Text(_initials(application)),
        ),
        title: Text(
          application.candidateName ??
              application.candidateEmail ??
              application.candidateUid,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitleParts.join(' • '),
          style: const TextStyle(color: muted, height: 1.35),
        ),
        trailing: application.id == null
            ? null
            : PopupMenuButton<String>(
                tooltip: 'Actualizar estado',
                onSelected: (value) {
                  context.read<OfferApplicantsCubit>().updateApplicationStatus(
                    offerId: offerId,
                    applicationId: application.id!,
                    newStatus: value,
                    companyUid: companyUid,
                  );
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
                          Text(_statusLabel(status)),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Chip(
                  label: Text(_statusLabel(application.status)),
                  side: const BorderSide(color: border),
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(color: ink),
                ),
              ),
      ),
    );
  }
}

const _applicationStatuses = [
  'pending',
  'reviewing',
  'interview',
  'accepted',
  'rejected',
];

String _statusLabel(String status) {
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
