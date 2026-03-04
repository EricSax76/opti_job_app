import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/evaluations/cubits/evaluation_form_cubit.dart';
import 'package:opti_job_app/modules/evaluations/models/evaluation.dart';
import 'package:opti_job_app/modules/evaluations/models/scorecard_template.dart';
import 'package:opti_job_app/modules/evaluations/ui/widgets/scorecard_criteria_slider.dart';

class EvaluationFormScreen extends StatelessWidget {
  const EvaluationFormScreen({
    super.key,
    required this.template,
    required this.applicationId,
    required this.jobOfferId,
    required this.companyId,
    required this.evaluatorUid,
    required this.evaluatorName,
    this.existingEvaluation,
  });

  final ScorecardTemplate template;
  final String applicationId;
  final String jobOfferId;
  final String companyId;
  final String evaluatorUid;
  final String evaluatorName;
  final Evaluation? existingEvaluation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EvaluationFormCubit(
        repository: context
            .read(), // Assuming repository is provided at a higher level
      )..init(template, existingEvaluation: existingEvaluation),
      child: BlocListener<EvaluationFormCubit, EvaluationFormState>(
        listener: (context, state) {
          if (state.status == EvaluationFormStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Evaluation submitted successfully'),
              ),
            );
            Navigator.pop(context);
          } else if (state.status == EvaluationFormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to submit evaluation')),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              existingEvaluation == null ? 'New Evaluation' : 'Edit Evaluation',
            ),
          ),
          body: BlocBuilder<EvaluationFormCubit, EvaluationFormState>(
            builder: (context, state) {
              if (state.template == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(uiSpacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: state.template!.name,
                      subtitle: 'Evaluación estructurada por criterios.',
                      titleFontSize: 24,
                    ),
                    const SizedBox(height: uiSpacing24),
                    ...state.template!.criteria.map((criteria) {
                      return ScorecardCriteriaSlider(
                        name: criteria.name,
                        description: criteria.description,
                        rating: state.criteriaRatings[criteria.id] ?? 3,
                        notes: state.criteriaNotes[criteria.id],
                        onChanged: (rating) {
                          context.read<EvaluationFormCubit>().updateRating(
                            criteria.id,
                            rating,
                          );
                        },
                        onNotesChanged: (notes) {
                          context.read<EvaluationFormCubit>().updateNotes(
                            criteria.id,
                            notes,
                          );
                        },
                      );
                    }),
                    const Divider(height: uiSpacing48),
                    AppCard(
                      padding: const EdgeInsets.all(uiSpacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overall Recommendation',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: uiSpacing16),
                          _RecommendationSelector(
                            selected: state.recommendation,
                            onSelected: (rec) {
                              context
                                  .read<EvaluationFormCubit>()
                                  .updateRecommendation(rec);
                            },
                          ),
                          const SizedBox(height: uiSpacing24),
                          Text(
                            'Overall Comments',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: uiSpacing8),
                          TextField(
                            onChanged: (value) => context
                                .read<EvaluationFormCubit>()
                                .updateComments(value),
                            decoration: const InputDecoration(
                              hintText:
                                  'Add final comments or justification...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                            controller:
                                TextEditingController(text: state.comments)
                                  ..selection = TextSelection.collapsed(
                                    offset: state.comments.length,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: uiSpacing24),
                    AppCard(
                      padding: const EdgeInsets.all(uiSpacing16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Overall Score'),
                                Text(
                                  state.overallScore.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                state.status == EvaluationFormStatus.submitting
                                ? null
                                : () {
                                    context
                                        .read<EvaluationFormCubit>()
                                        .submitEvaluation(
                                          applicationId: applicationId,
                                          jobOfferId: jobOfferId,
                                          companyId: companyId,
                                          evaluatorUid: evaluatorUid,
                                          evaluatorName: evaluatorName,
                                        );
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: uiSpacing32,
                                vertical: uiSpacing16,
                              ),
                            ),
                            child:
                                state.status == EvaluationFormStatus.submitting
                                ? CircularProgressIndicator(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  )
                                : const Text('SUBMIT EVALUATION'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: uiSpacing32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecommendationSelector extends StatelessWidget {
  const _RecommendationSelector({
    required this.selected,
    required this.onSelected,
  });

  final Recommendation selected;
  final ValueChanged<Recommendation> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: Recommendation.values.map((rec) {
        final isSelected = selected == rec;
        return Padding(
          padding: const EdgeInsets.only(bottom: uiSpacing8),
          child: InkWell(
            onTap: () => onSelected(rec),
            child: AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: uiSpacing16,
                vertical: uiSpacing12,
              ),
              backgroundColor: isSelected
                  ? _getColor(context, rec).withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
              borderColor: isSelected
                  ? _getColor(context, rec)
                  : Theme.of(context).colorScheme.outlineVariant,
              borderRadius: uiSpacing8,
              borderWidth: isSelected ? 2 : 1,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? _getColor(context, rec)
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: uiSpacing12),
                  Text(
                    _getLabel(rec),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? _getColor(context, rec)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _getEmoji(context, rec),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColor(BuildContext context, Recommendation rec) {
    final scheme = Theme.of(context).colorScheme;
    switch (rec) {
      case Recommendation.strongYes:
        return scheme.tertiary.withValues(alpha: 0.85);
      case Recommendation.yes:
        return scheme.tertiary;
      case Recommendation.neutral:
        return scheme.primary;
      case Recommendation.no:
        return scheme.error;
      case Recommendation.strongNo:
        return scheme.error.withValues(alpha: 0.85);
    }
  }

  String _getLabel(Recommendation rec) {
    switch (rec) {
      case Recommendation.strongYes:
        return 'Strong Yes';
      case Recommendation.yes:
        return 'Yes';
      case Recommendation.neutral:
        return 'Neutral';
      case Recommendation.no:
        return 'No';
      case Recommendation.strongNo:
        return 'Strong No';
    }
  }

  Widget _getEmoji(BuildContext context, Recommendation rec) {
    String emoji;
    switch (rec) {
      case Recommendation.strongYes:
        emoji = '🤩';
        break;
      case Recommendation.yes:
        emoji = '🙂';
        break;
      case Recommendation.neutral:
        emoji = '😐';
        break;
      case Recommendation.no:
        emoji = '🙁';
        break;
      case Recommendation.strongNo:
        emoji = '😡';
        break;
    }
    return Text(emoji, style: Theme.of(context).textTheme.titleLarge);
  }
}
