import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/aplications/cubits/offer_applicants_cubit.dart';
import 'package:opti_job_app/modules/aplications/models/application.dart';
import 'package:opti_job_app/modules/aplications/ui/application_status.dart';

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
    const background = uiBackground;
    const ink = uiInk;
    const muted = uiMuted;
    const border = uiBorder;

    final subtitleParts = <String>[];
    if (application.candidateEmail != null &&
        application.candidateEmail!.isNotEmpty) {
      subtitleParts.add(application.candidateEmail!);
    }
    subtitleParts.add(
      'Estado: ${applicationStatusLabel(application.status)}',
    );

    return Container(
      decoration: BoxDecoration(
        color: background,
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
                          Text(applicationStatusLabel(status)),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Chip(
                  label: Text(applicationStatusLabel(application.status)),
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
