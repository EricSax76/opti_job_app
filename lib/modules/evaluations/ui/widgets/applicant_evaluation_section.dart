import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/evaluations/cubits/evaluation_summary_cubit.dart';
import 'package:opti_job_app/modules/evaluations/logic/applicant_evaluation_logic.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';
import 'package:opti_job_app/modules/evaluations/repositories/evaluation_repository.dart';
import 'package:opti_job_app/modules/evaluations/ui/controllers/applicant_evaluation_actions_controller.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/applicant_evaluation_content.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/applicant_evaluation_dialogs.dart';
import 'package:opti_job_app/modules/recruiters/cubits/recruiter_auth_cubit.dart';
import 'package:opti_job_app/modules/recruiters/services/rbac_service.dart';

class ApplicantEvaluationSection extends StatefulWidget {
  const ApplicantEvaluationSection({
    super.key,
    required this.applicationId,
    required this.jobOfferId,
    required this.companyUid,
  });

  final String applicationId;
  final String jobOfferId;
  final String companyUid;

  @override
  State<ApplicantEvaluationSection> createState() =>
      _ApplicantEvaluationSectionState();
}

class _ApplicantEvaluationSectionState
    extends State<ApplicantEvaluationSection> {
  final Map<String, List<ScorecardTemplate>> _templatesByCompanyUid = {};

  EvaluationSummaryCubit? _summaryCubit;
  bool _isLoadingTemplate = false;
  bool _isRequestingApproval = false;

  String get _applicationId => widget.applicationId.trim();
  String get _jobOfferId => widget.jobOfferId.trim();

  @override
  void initState() {
    super.initState();
    _initializeSummaryCubit();
  }

  @override
  void didUpdateWidget(covariant ApplicantEvaluationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.applicationId.trim() != _applicationId) {
      _summaryCubit?.close();
      _summaryCubit = null;
      _initializeSummaryCubit();
    }
  }

  @override
  void dispose() {
    _summaryCubit?.close();
    super.dispose();
  }

  void _initializeSummaryCubit() {
    if (_applicationId.isEmpty) return;

    _summaryCubit = EvaluationSummaryCubit(
      repository: context.read<EvaluationRepository>(),
    )..loadSummary(_applicationId);
  }

  @override
  Widget build(BuildContext context) {
    if (_applicationId.isEmpty) {
      return const Text(
        'No hay contexto de candidatura (applicationId) para habilitar evaluaciones.',
      );
    }

    final summaryCubit = _summaryCubit;
    if (summaryCubit == null) {
      return const Text('No se pudo inicializar el módulo de evaluaciones.');
    }

    final companyState = context.watch<CompanyAuthCubit>().state;
    final company = companyState.company;
    final recruiter = context.watch<RecruiterAuthCubit>().state.recruiter;

    final actor = ApplicantEvaluationLogic.resolveActor(
      isCompanyAuthenticated: companyState.isAuthenticated,
      companyUid: company?.uid,
      companyName: company?.name,
      recruiter: recruiter,
      rbacService: context.read<RbacService>(),
    );

    return BlocProvider.value(
      value: summaryCubit,
      child: BlocBuilder<EvaluationSummaryCubit, EvaluationSummaryState>(
        builder: (context, state) {
          return ApplicantEvaluationContent(
            state: state,
            actor: actor,
            isLoadingTemplate: _isLoadingTemplate,
            isRequestingApproval: _isRequestingApproval,
            onNewEvaluation: () => _handleOpenEvaluation(actor: actor),
            onRequestApproval: () => _handleRequestApproval(actor: actor),
            onRefresh: () => summaryCubit.loadSummary(_applicationId),
            onOverrideAiEvaluation: () => _handleOpenEvaluation(
              actor: actor,
              existingEvaluation: ApplicantEvaluationLogic.latestAiEvaluation(
                state.evaluations,
              ),
            ),
            onEvaluationTap: (evaluation) =>
                showEvaluationDetailsDialog(context, evaluation),
            onApprovalDecision: actor == null
                ? null
                : (approvalId, status, notes) async {
                    await summaryCubit.updateApproval(
                      approvalId,
                      actor.uid,
                      status,
                      notes: notes,
                    );
                    await summaryCubit.loadSummary(_applicationId);
                  },
            onPermissionDeniedForOverride: () =>
                ApplicantEvaluationActionsController.showPermissionDeniedForOverrideMessage(
                  context,
                ),
          );
        },
      ),
    );
  }

  Future<void> _handleOpenEvaluation({
    required ApplicantEvaluationActor? actor,
    Evaluation? existingEvaluation,
  }) async {
    if (_isLoadingTemplate) return;

    setState(() => _isLoadingTemplate = true);
    try {
      final shouldRefresh =
          await ApplicantEvaluationActionsController.openEvaluationForm(
            context: context,
            actor: actor,
            routeCompanyUid: widget.companyUid,
            applicationId: _applicationId,
            jobOfferId: _jobOfferId,
            templatesByCompanyUid: _templatesByCompanyUid,
            existingEvaluation: existingEvaluation,
          );

      if (shouldRefresh) {
        await _summaryCubit?.loadSummary(_applicationId);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTemplate = false);
      }
    }
  }

  Future<void> _handleRequestApproval({
    required ApplicantEvaluationActor? actor,
  }) async {
    if (_isRequestingApproval) return;

    setState(() => _isRequestingApproval = true);
    try {
      final shouldRefresh =
          await ApplicantEvaluationActionsController.requestApproval(
            context: context,
            actor: actor,
            routeCompanyUid: widget.companyUid,
            applicationId: _applicationId,
            jobOfferId: _jobOfferId,
          );

      if (shouldRefresh) {
        await _summaryCubit?.loadSummary(_applicationId);
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingApproval = false);
      }
    }
  }
}
