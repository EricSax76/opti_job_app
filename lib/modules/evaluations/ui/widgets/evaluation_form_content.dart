import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/evaluations/cubits/evaluation_form_cubit.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/evaluation_recommendation_selector.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/scorecard_criteria_slider.dart';

class EvaluationFormContent extends StatelessWidget {
  const EvaluationFormContent({
    super.key,
    required this.applicationId,
    required this.jobOfferId,
    required this.companyId,
    required this.evaluatorUid,
    required this.evaluatorName,
  });

  final String applicationId;
  final String jobOfferId;
  final String companyId;
  final String evaluatorUid;
  final String evaluatorName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EvaluationFormCubit, EvaluationFormState>(
      builder: (context, state) {
        final template = state.template;
        if (template == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final cubit = context.read<EvaluationFormCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(uiSpacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: template.name,
                subtitle: 'Evaluación estructurada por criterios.',
                titleFontSize: 24,
              ),
              const SizedBox(height: uiSpacing24),
              ...template.criteria.map(
                (criteria) => ScorecardCriteriaSlider(
                  name: criteria.name,
                  description: criteria.description,
                  rating: state.criteriaRatings[criteria.id] ?? 3,
                  notes: state.criteriaNotes[criteria.id],
                  onChanged: (rating) =>
                      cubit.updateRating(criteria.id, rating),
                  onNotesChanged: (notes) =>
                      cubit.updateNotes(criteria.id, notes),
                ),
              ),
              const Divider(height: uiSpacing48),
              _EvaluationRecommendationCard(
                recommendation: state.recommendation,
                comments: state.comments,
                onRecommendationSelected: cubit.updateRecommendation,
                onCommentsChanged: cubit.updateComments,
              ),
              const SizedBox(height: uiSpacing24),
              _EvaluationSubmitCard(
                overallScore: state.overallScore,
                isSubmitting: state.status == EvaluationFormStatus.submitting,
                onSubmit: () => cubit.submitEvaluation(
                  applicationId: applicationId,
                  jobOfferId: jobOfferId,
                  companyId: companyId,
                  evaluatorUid: evaluatorUid,
                  evaluatorName: evaluatorName,
                ),
              ),
              const SizedBox(height: uiSpacing32),
            ],
          ),
        );
      },
    );
  }
}

class _EvaluationRecommendationCard extends StatelessWidget {
  const _EvaluationRecommendationCard({
    required this.recommendation,
    required this.comments,
    required this.onRecommendationSelected,
    required this.onCommentsChanged,
  });

  final Recommendation recommendation;
  final String comments;
  final ValueChanged<Recommendation> onRecommendationSelected;
  final ValueChanged<String> onCommentsChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Recommendation',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: uiSpacing16),
          EvaluationRecommendationSelector(
            selected: recommendation,
            onSelected: onRecommendationSelected,
          ),
          const SizedBox(height: uiSpacing24),
          Text(
            'Overall Comments',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: uiSpacing8),
          TextFormField(
            initialValue: comments,
            onChanged: onCommentsChanged,
            decoration: const InputDecoration(
              hintText: 'Add final comments or justification...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class _EvaluationSubmitCard extends StatelessWidget {
  const _EvaluationSubmitCard({
    required this.overallScore,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final double overallScore;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Score'),
                Text(
                  overallScore.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: uiSpacing32,
                vertical: uiSpacing16,
              ),
            ),
            child: isSubmitting
                ? CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : const Text('SUBMIT EVALUATION'),
          ),
        ],
      ),
    );
  }
}
