import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/compliance/logic/candidate_privacy_portal_logic.dart';
import 'package:opti_job_app/modules/compliance/logic/data_request_labels.dart';
import 'package:opti_job_app/modules/compliance/models/data_request.dart';

typedef CandidatePrivacyRequestInput = ({
  String description,
  String? applicationId,
  String? companyId,
});

Future<void> showCandidatePrivacyExportDialog(
  BuildContext context, {
  required CandidatePrivacyExportSummary summary,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Exportación de datos lista'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Candidaturas: ${summary.applicationsCount}'),
            Text('Consentimientos: ${summary.consentsCount}'),
            Text('Solicitudes de privacidad: ${summary.requestsCount}'),
            Text('Notas de reclutador: ${summary.notesCount}'),
            if (summary.exportedAt != null)
              Text('Generado: ${summary.exportedAt!}'),
            const SizedBox(height: uiSpacing12),
            const Text(
              'Puedes copiar el JSON completo para tu solicitud ARSULIPO.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: const JsonEncoder.withIndent(
                    '  ',
                  ).convert(summary.rawPayload),
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copiado al portapapeles.')),
              );
            },
            child: const Text('Copiar JSON'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

Future<CandidatePrivacyRequestInput?> showCandidatePrivacyRequestDialog(
  BuildContext context, {
  required DataRequestType type,
}) async {
  final descriptionController = TextEditingController();
  final applicationController = TextEditingController();
  final companyController = TextEditingController();

  final input = await showDialog<CandidatePrivacyRequestInput>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(DataRequestLabels.dialogTitle(type)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DataRequestLabels.dialogDescription(type)),
            const SizedBox(height: uiSpacing8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (type == DataRequestType.aiExplanation ||
                type == DataRequestType.salaryComparison) ...[
              const SizedBox(height: uiSpacing8),
              TextField(
                controller: applicationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ID de candidatura (opcional)',
                ),
              ),
              const SizedBox(height: uiSpacing8),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'ID de empresa (opcional)',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final applicationId = applicationController.text.trim();
              final companyId = companyController.text.trim();
              Navigator.of(context).pop((
                description: descriptionController.text,
                applicationId: applicationId.isEmpty ? null : applicationId,
                companyId: companyId.isEmpty ? null : companyId,
              ));
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      );
    },
  );

  descriptionController.dispose();
  applicationController.dispose();
  companyController.dispose();
  return input;
}
