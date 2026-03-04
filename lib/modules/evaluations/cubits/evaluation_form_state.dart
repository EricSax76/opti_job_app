part of 'evaluation_form_cubit.dart';

enum EvaluationFormStatus { initial, submitting, success, failure }

class EvaluationFormState extends Equatable {
  final ScorecardTemplate? template;
  final Map<String, int> criteriaRatings;
  final Map<String, String> criteriaNotes;
  final String comments;
  final Recommendation recommendation;
  final double overallScore;
  final EvaluationFormStatus status;

  const EvaluationFormState({
    this.template,
    this.criteriaRatings = const {},
    this.criteriaNotes = const {},
    this.comments = '',
    this.recommendation = Recommendation.neutral,
    this.overallScore = 0.0,
    this.status = EvaluationFormStatus.initial,
  });

  EvaluationFormState copyWith({
    ScorecardTemplate? template,
    Map<String, int>? criteriaRatings,
    Map<String, String>? criteriaNotes,
    String? comments,
    Recommendation? recommendation,
    double? overallScore,
    EvaluationFormStatus? status,
  }) {
    return EvaluationFormState(
      template: template ?? this.template,
      criteriaRatings: criteriaRatings ?? this.criteriaRatings,
      criteriaNotes: criteriaNotes ?? this.criteriaNotes,
      comments: comments ?? this.comments,
      recommendation: recommendation ?? this.recommendation,
      overallScore: overallScore ?? this.overallScore,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        template,
        criteriaRatings,
        criteriaNotes,
        comments,
        recommendation,
        overallScore,
        status,
      ];
}
