import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_onboarding_preferences.dart';

class CandidateOnboardingProfileBasicsStep extends StatelessWidget {
  const CandidateOnboardingProfileBasicsStep({
    super.key,
    required this.targetRole,
    required this.preferredLocation,
    required this.preferredModality,
    required this.preferredSeniority,
    required this.onTargetRoleChanged,
    required this.onPreferredLocationChanged,
    required this.onPreferredModalityChanged,
    required this.onPreferredSeniorityChanged,
    this.validationMessage,
  });

  final String targetRole;
  final String preferredLocation;
  final String preferredModality;
  final String preferredSeniority;
  final ValueChanged<String> onTargetRoleChanged;
  final ValueChanged<String> onPreferredLocationChanged;
  final ValueChanged<String> onPreferredModalityChanged;
  final ValueChanged<String> onPreferredSeniorityChanged;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const ValueKey('onboarding_target_role_input'),
          initialValue: targetRole,
          decoration: const InputDecoration(
            labelText: 'Rol objetivo',
            hintText: 'Ej: Flutter Developer',
          ),
          textInputAction: TextInputAction.next,
          onChanged: onTargetRoleChanged,
        ),
        const SizedBox(height: uiSpacing12),
        TextFormField(
          key: const ValueKey('onboarding_location_input'),
          initialValue: preferredLocation,
          decoration: const InputDecoration(
            labelText: 'Ubicación preferida',
            hintText: 'Ej: Madrid o remoto',
          ),
          textInputAction: TextInputAction.done,
          onChanged: onPreferredLocationChanged,
        ),
        const SizedBox(height: uiSpacing16),
        _SelectionChipSection(
          title: 'Modalidad',
          options: CandidateOnboardingPreferences.modalityOptions,
          selectedValue: preferredModality,
          onSelected: onPreferredModalityChanged,
        ),
        const SizedBox(height: uiSpacing16),
        _SelectionChipSection(
          title: 'Nivel de experiencia',
          options: CandidateOnboardingPreferences.seniorityOptions,
          selectedValue: preferredSeniority,
          onSelected: onPreferredSeniorityChanged,
        ),
        const SizedBox(height: uiSpacing12),
        Text(
          'Solo pedimos lo esencial para personalizar tus primeras recomendaciones.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
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

class _SelectionChipSection extends StatelessWidget {
  const _SelectionChipSection({
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
