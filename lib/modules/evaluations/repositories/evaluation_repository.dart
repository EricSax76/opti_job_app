import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';

abstract class EvaluationRepository {
  Future<List<ScorecardTemplate>> getScorecardTemplates(String companyId);
  Future<void> submitEvaluation(Evaluation evaluation);
  Future<List<Evaluation>> getEvaluationsForApplication(String applicationId);
  Future<void> requestApproval(Approval approval);
  Future<List<Approval>> getApprovalsForApplication(String applicationId);
  Future<void> updateApprovalStatus(String approvalId, String approverUid, ApprovalStatus status, {String? notes});
}
