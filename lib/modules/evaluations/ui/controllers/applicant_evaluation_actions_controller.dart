import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/evaluations/logic/applicant_evaluation_logic.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';
import 'package:opti_job_app/modules/evaluations/repositories/evaluation_repository.dart';
import 'package:opti_job_app/modules/evaluations/ui/pages/evaluation_form_screen.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/applicant_evaluation_dialogs.dart';

class ApplicantEvaluationActionsController {
  const ApplicantEvaluationActionsController._();

  static Future<bool> openEvaluationForm({
    required BuildContext context,
    required ApplicantEvaluationActor? actor,
    required String routeCompanyUid,
    required String applicationId,
    required String jobOfferId,
    required Map<String, List<ScorecardTemplate>> templatesByCompanyUid,
    Evaluation? existingEvaluation,
  }) async {
    if (actor == null || !actor.canScore) {
      _showMessage(
        context,
        'Tu rol no tiene permisos para evaluar candidaturas.',
      );
      return false;
    }

    final companyUid = ApplicantEvaluationLogic.resolveCompanyUid(
      routeCompanyUid: routeCompanyUid,
      actor: actor,
    );
    if (companyUid.isEmpty) {
      _showMessage(
        context,
        'No se pudo resolver la empresa para esta evaluación.',
      );
      return false;
    }

    try {
      final template = existingEvaluation != null
          ? ApplicantEvaluationLogic.templateFromExistingEvaluation(
              evaluation: existingEvaluation,
              companyUid: companyUid,
              createdBy: actor.uid,
            )
          : await _pickTemplate(
              context: context,
              companyUid: companyUid,
              templatesByCompanyUid: templatesByCompanyUid,
            );

      if (!context.mounted || template == null) return false;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EvaluationFormScreen(
            template: template,
            applicationId: applicationId,
            jobOfferId: jobOfferId,
            companyId: companyUid,
            evaluatorUid: actor.uid,
            evaluatorName: actor.name,
            existingEvaluation: existingEvaluation,
          ),
        ),
      );

      return context.mounted;
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'No se pudo abrir el formulario de evaluación.');
      }
      return false;
    }
  }

  static Future<bool> requestApproval({
    required BuildContext context,
    required ApplicantEvaluationActor? actor,
    required String routeCompanyUid,
    required String applicationId,
    required String jobOfferId,
  }) async {
    if (actor == null || !actor.canRequestApprovals) {
      _showMessage(context, 'Tu rol no puede solicitar aprobaciones.');
      return false;
    }

    final companyUid = ApplicantEvaluationLogic.resolveCompanyUid(
      routeCompanyUid: routeCompanyUid,
      actor: actor,
    );
    if (companyUid.isEmpty) {
      _showMessage(
        context,
        'No se pudo resolver la empresa para solicitar aprobación.',
      );
      return false;
    }

    final request = await showApprovalRequestDialog(context);
    if (!context.mounted || request == null) return false;

    try {
      await context.read<EvaluationRepository>().requestApproval(
        Approval(
          id: '',
          applicationId: applicationId,
          jobOfferId: jobOfferId,
          companyId: companyUid,
          type: request.type,
          requestedBy: actor.uid,
          approvers: request.approvers,
          status: ApprovalStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      if (context.mounted) {
        _showMessage(context, 'Solicitud de aprobación enviada.');
      }
      return true;
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'No se pudo solicitar la aprobación.');
      }
      return false;
    }
  }

  static void showPermissionDeniedForOverrideMessage(BuildContext context) {
    _showMessage(
      context,
      'Tu rol no tiene permisos para actualizar evaluaciones.',
    );
  }

  static Future<ScorecardTemplate?> _pickTemplate({
    required BuildContext context,
    required String companyUid,
    required Map<String, List<ScorecardTemplate>> templatesByCompanyUid,
  }) async {
    final templates = await _loadTemplatesForCompany(
      context: context,
      companyUid: companyUid,
      templatesByCompanyUid: templatesByCompanyUid,
    );
    if (!context.mounted) return null;

    if (templates.isEmpty) {
      _showMessage(
        context,
        'No hay scorecards configurados para esta empresa.',
      );
      return null;
    }
    if (templates.length == 1) return templates.first;

    return showScorecardTemplatePickerSheet(context, templates: templates);
  }

  static Future<List<ScorecardTemplate>> _loadTemplatesForCompany({
    required BuildContext context,
    required String companyUid,
    required Map<String, List<ScorecardTemplate>> templatesByCompanyUid,
  }) async {
    final normalizedCompanyUid = companyUid.trim();
    if (normalizedCompanyUid.isEmpty) return const [];

    final cached = templatesByCompanyUid[normalizedCompanyUid];
    if (cached != null) return cached;

    final templates = await context
        .read<EvaluationRepository>()
        .getScorecardTemplates(normalizedCompanyUid);
    templatesByCompanyUid[normalizedCompanyUid] = templates;
    return templates;
  }

  static void _showMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
