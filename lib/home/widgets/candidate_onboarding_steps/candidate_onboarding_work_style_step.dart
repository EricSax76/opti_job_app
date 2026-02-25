import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_onboarding_preferences.dart';

class CandidateOnboardingWorkStyleStep extends StatelessWidget {
  const CandidateOnboardingWorkStyleStep({
    super.key,
    required this.startOfDayPreference,
    required this.feedbackPreference,
    required this.structurePreference,
    required this.taskPacePreference,
    required this.onStartOfDayChanged,
    required this.onFeedbackChanged,
    required this.onStructureChanged,
    required this.onTaskPaceChanged,
  });

  final String startOfDayPreference;
  final String feedbackPreference;
  final String structurePreference;
  final String taskPacePreference;
  final ValueChanged<String> onStartOfDayChanged;
  final ValueChanged<String> onFeedbackChanged;
  final ValueChanged<String> onStructureChanged;
  final ValueChanged<String> onTaskPaceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final questions = [
      _WorkStyleQuestion(
        title:
            'En un lunes ideal, prefieres arrancar con foco individual o con sincronización de equipo?',
        options: CandidateOnboardingPreferences.startOfDayOptions,
        selectedValue: startOfDayPreference,
        onSelected: onStartOfDayChanged,
      ),
      _WorkStyleQuestion(
        title: 'Qué tipo de feedback te impulsa más?',
        options: CandidateOnboardingPreferences.feedbackOptions,
        selectedValue: feedbackPreference,
        onSelected: onFeedbackChanged,
      ),
      _WorkStyleQuestion(
        title: 'Qué entorno te funciona mejor para rendir?',
        options: CandidateOnboardingPreferences.structureOptions,
        selectedValue: structurePreference,
        onSelected: onStructureChanged,
      ),
      _WorkStyleQuestion(
        title: 'Cómo prefieres distribuir tu jornada?',
        options: CandidateOnboardingPreferences.taskPaceOptions,
        selectedValue: taskPacePreference,
        onSelected: onTaskPaceChanged,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < questions.length; index++) ...[
          _WorkStyleQuestionCard(
            title: questions[index].title,
            options: questions[index].options,
            selectedValue: questions[index].selectedValue,
            onSelected: questions[index].onSelected,
          ),
          if (index < questions.length - 1) const SizedBox(height: uiSpacing12),
        ],
        const SizedBox(height: uiSpacing12),
        Text(
          'Opcional: estas respuestas mejoran el matching con culturas de trabajo compatibles.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WorkStyleQuestion {
  const _WorkStyleQuestion({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
}

class _WorkStyleQuestionCard extends StatelessWidget {
  const _WorkStyleQuestionCard({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(uiSpacing12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: uiSpacing12),
          Wrap(
            spacing: uiSpacing8,
            runSpacing: uiSpacing8,
            children: options
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: selectedValue == option,
                    onSelected: (_) => onSelected(option),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
