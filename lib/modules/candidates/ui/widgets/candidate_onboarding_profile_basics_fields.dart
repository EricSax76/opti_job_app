import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_onboarding_preferences.dart';

class CandidateOnboardingProfileBasicsFields extends StatelessWidget {
  const CandidateOnboardingProfileBasicsFields({
    super.key,
    required this.targetRoleField,
    required this.preferredLocationField,
    required this.preferredModality,
    required this.preferredSeniority,
    required this.onPreferredModalityChanged,
    required this.onPreferredSeniorityChanged,
    this.helperMessage,
    this.validationMessage,
  });

  final Widget targetRoleField;
  final Widget preferredLocationField;
  final String preferredModality;
  final String preferredSeniority;
  final ValueChanged<String> onPreferredModalityChanged;
  final ValueChanged<String> onPreferredSeniorityChanged;
  final String? helperMessage;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        targetRoleField,
        const SizedBox(height: uiSpacing12),
        preferredLocationField,
        const SizedBox(height: uiSpacing16),
        CandidateOnboardingChoiceChipSection(
          title: 'Modalidad',
          options: CandidateOnboardingPreferences.modalityOptions,
          selectedValue: preferredModality,
          onSelected: onPreferredModalityChanged,
        ),
        const SizedBox(height: uiSpacing16),
        CandidateOnboardingChoiceChipSection(
          title: 'Nivel de experiencia',
          options: CandidateOnboardingPreferences.seniorityOptions,
          selectedValue: preferredSeniority,
          onSelected: onPreferredSeniorityChanged,
        ),
        if (helperMessage != null) ...[
          const SizedBox(height: uiSpacing12),
          Text(
            helperMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (validationMessage != null) ...[
          const SizedBox(height: uiSpacing12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: uiSpacing12,
              vertical: uiSpacing8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.errorContainer.withValues(alpha: 0.7),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              validationMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CandidateOnboardingChoiceChipSection extends StatelessWidget {
  const CandidateOnboardingChoiceChipSection({
    super.key,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: uiSpacing8),
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
    );
  }
}
