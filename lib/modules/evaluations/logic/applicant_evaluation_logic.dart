import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter.dart';
import 'package:opti_job_app/modules/recruiters/models/recruiter_role.dart';
import 'package:opti_job_app/modules/recruiters/services/rbac_service.dart';

class ApplicantEvaluationActor {
  const ApplicantEvaluationActor({
    required this.uid,
    required this.name,
    required this.canScore,
    required this.canRequestApprovals,
    required this.isCompanyUser,
  });

  final String uid;
  final String name;
  final bool canScore;
  final bool canRequestApprovals;
  final bool isCompanyUser;
}

class ApprovalRequestInput {
  const ApprovalRequestInput({required this.type, required this.approvers});

  final ApprovalType type;
  final List<Approver> approvers;
}

class ApplicantEvaluationLogic {
  static ApplicantEvaluationActor? resolveActor({
    required bool isCompanyAuthenticated,
    required String? companyUid,
    required String? companyName,
    required Recruiter? recruiter,
    required RbacService rbacService,
  }) {
    final normalizedCompanyUid = (companyUid ?? '').trim();
    if (isCompanyAuthenticated && normalizedCompanyUid.isNotEmpty) {
      final normalizedCompanyName = (companyName ?? '').trim();
      return ApplicantEvaluationActor(
        uid: normalizedCompanyUid,
        name: normalizedCompanyName.isEmpty ? 'Empresa' : normalizedCompanyName,
        canScore: true,
        canRequestApprovals: true,
        isCompanyUser: true,
      );
    }

    if (recruiter == null || !recruiter.isActive) return null;

    final canRequestApprovals = switch (recruiter.role) {
      RecruiterRole.admin => true,
      RecruiterRole.recruiter => true,
      RecruiterRole.hiringManager => true,
      _ => false,
    };

    final recruiterUid = recruiter.uid.trim();
    if (recruiterUid.isEmpty) return null;

    final recruiterName = recruiter.name.trim().isNotEmpty
        ? recruiter.name.trim()
        : recruiter.email.trim();

    return ApplicantEvaluationActor(
      uid: recruiterUid,
      name: recruiterName,
      canScore: rbacService.canScore(recruiter),
      canRequestApprovals: canRequestApprovals,
      isCompanyUser: false,
    );
  }

  static String resolveCompanyUid({
    required String routeCompanyUid,
    required ApplicantEvaluationActor? actor,
  }) {
    final normalizedRouteCompanyUid = routeCompanyUid.trim();
    if (normalizedRouteCompanyUid.isNotEmpty) return normalizedRouteCompanyUid;
    if (actor?.isCompanyUser == true) return actor!.uid;
    return '';
  }

  static Evaluation? latestAiEvaluation(List<Evaluation> evaluations) {
    for (final evaluation in evaluations) {
      if (evaluation.aiAssisted) return evaluation;
    }
    return null;
  }

  static ScorecardTemplate templateFromExistingEvaluation({
    required Evaluation evaluation,
    required String companyUid,
    required String createdBy,
  }) {
    return ScorecardTemplate(
      id: 'existing-${evaluation.id}',
      companyId: companyUid,
      name: 'Reevaluación',
      criteria: evaluation.criteria
          .map(
            (criteria) => ScorecardCriteria(
              id: criteria.id,
              name: criteria.name,
              description: '',
              weight: criteria.weight,
            ),
          )
          .toList(),
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  static List<Approver>? parseApprovers(String raw) {
    final entries = raw
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
    if (entries.isEmpty) return null;

    final approvers = <Approver>[];
    for (final entry in entries) {
      final separator = entry.indexOf(':');
      if (separator <= 0 || separator >= entry.length - 1) return null;

      final uid = entry.substring(0, separator).trim();
      final name = entry.substring(separator + 1).trim();
      if (uid.isEmpty || name.isEmpty) return null;

      approvers.add(
        Approver(uid: uid, name: name, status: ApprovalStatus.pending),
      );
    }

    return approvers;
  }
}
