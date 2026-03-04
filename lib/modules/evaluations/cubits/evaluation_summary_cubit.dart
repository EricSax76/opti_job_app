import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/approval.dart';
import 'package:opti_job_app/modules/evaluations/repositories/evaluation_repository.dart';

part 'evaluation_summary_state.dart';

class EvaluationSummaryCubit extends Cubit<EvaluationSummaryState> {
  final EvaluationRepository _repository;

  EvaluationSummaryCubit({
    required EvaluationRepository repository,
  })  : _repository = repository,
        super(const EvaluationSummaryState());

  Future<void> loadSummary(String applicationId) async {
    emit(state.copyWith(status: EvaluationSummaryStatus.loading));

    try {
      final evaluations = await _repository.getEvaluationsForApplication(applicationId);
      final approvals = await _repository.getApprovalsForApplication(applicationId);

      emit(state.copyWith(
        evaluations: evaluations,
        approvals: approvals,
        status: EvaluationSummaryStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: EvaluationSummaryStatus.failure));
    }
  }

  Future<void> updateApproval(String approvalId, String approverUid, ApprovalStatus status, {String? notes}) async {
    try {
      await _repository.updateApprovalStatus(approvalId, approverUid, status, notes: notes);
      // Reload summary to reflect changes
      if (state.evaluations.isNotEmpty) {
        await loadSummary(state.evaluations.first.applicationId);
      }
    } catch (e) {
      // Handle error
    }
  }
}
