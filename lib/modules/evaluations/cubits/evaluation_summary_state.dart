part of 'evaluation_summary_cubit.dart';

enum EvaluationSummaryStatus { initial, loading, success, failure }

class EvaluationSummaryState extends Equatable {
  final List<Evaluation> evaluations;
  final List<Approval> approvals;
  final EvaluationSummaryStatus status;

  const EvaluationSummaryState({
    this.evaluations = const [],
    this.approvals = const [],
    this.status = EvaluationSummaryStatus.initial,
  });

  EvaluationSummaryState copyWith({
    List<Evaluation>? evaluations,
    List<Approval>? approvals,
    EvaluationSummaryStatus? status,
  }) {
    return EvaluationSummaryState(
      evaluations: evaluations ?? this.evaluations,
      approvals: approvals ?? this.approvals,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [evaluations, approvals, status];
}
