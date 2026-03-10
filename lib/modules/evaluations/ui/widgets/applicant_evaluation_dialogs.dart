import 'package:flutter/material.dart';
import 'package:opti_job_app/modules/evaluations/logic/applicant_evaluation_logic.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';

Future<ApprovalRequestInput?> showApprovalRequestDialog(
  BuildContext context,
) async {
  var selectedType = ApprovalType.offerApproval;
  var errorText = '';
  final approversController = TextEditingController();

  final result = await showDialog<ApprovalRequestInput>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Solicitar aprobación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ApprovalType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de aprobación',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ApprovalType.offerApproval,
                      child: Text('Aprobación de oferta'),
                    ),
                    DropdownMenuItem(
                      value: ApprovalType.salaryApproval,
                      child: Text('Aprobación salarial'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: approversController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Aprobadores',
                    hintText: 'uid1:Nombre 1, uid2:Nombre 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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
              FilledButton(
                onPressed: () {
                  final approvers = ApplicantEvaluationLogic.parseApprovers(
                    approversController.text,
                  );
                  if (approvers == null) {
                    setDialogState(() {
                      errorText =
                          'Formato inválido. Usa "uid:nombre" separados por coma.';
                    });
                    return;
                  }

                  Navigator.of(context).pop(
                    ApprovalRequestInput(
                      type: selectedType,
                      approvers: approvers,
                    ),
                  );
                },
                child: const Text('Solicitar'),
              ),
            ],
          );
        },
      );
    },
  );

  approversController.dispose();
  return result;
}

Future<void> showEvaluationDetailsDialog(
  BuildContext context,
  Evaluation evaluation,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Evaluación de ${evaluation.evaluatorName}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puntuación total: ${evaluation.overallScore.toStringAsFixed(1)}',
                ),
                Text('Recomendación: ${evaluation.recommendation.name}'),
                if (evaluation.comments.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(evaluation.comments.trim()),
                ],
                if (evaluation.criteria.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Criterios'),
                  const SizedBox(height: 6),
                  ...evaluation.criteria.map(
                    (criteria) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${criteria.name}: ${criteria.rating}/5'),
                      subtitle: criteria.notes.trim().isEmpty
                          ? null
                          : Text(criteria.notes.trim()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}

Future<ScorecardTemplate?> showScorecardTemplatePickerSheet(
  BuildContext context, {
  required List<ScorecardTemplate> templates,
}) {
  return showModalBottomSheet<ScorecardTemplate>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: templates
              .map(
                (template) => ListTile(
                  title: Text(template.name),
                  subtitle: Text('${template.criteria.length} criterios'),
                  onTap: () => Navigator.of(context).pop(template),
                ),
              )
              .toList(),
        ),
      );
    },
  );
}
