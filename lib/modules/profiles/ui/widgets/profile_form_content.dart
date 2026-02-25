import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/home/widgets/candidate_onboarding_steps/candidate_onboarding_work_style_step.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';
import 'package:opti_job_app/modules/candidates/models/candidate_onboarding_preferences.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_form_state.dart';
import 'package:opti_job_app/modules/profiles/logic/profile_form_logic.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_avatar.dart';

class ProfileFormContent extends StatelessWidget {
  const ProfileFormContent({
    super.key,
    required this.formKey,
    required this.state,
    required this.nameController,
    required this.lastNameController,
    required this.emailController,
    required this.targetRoleController,
    required this.preferredLocationController,
    required this.onboardingDraft,
    required this.onPickAvatar,
    required this.onPreferredModalityChanged,
    required this.onPreferredSeniorityChanged,
    required this.onWorkStyleSkippedChanged,
    required this.onStartOfDayChanged,
    required this.onFeedbackChanged,
    required this.onStructureChanged,
    required this.onTaskPaceChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormState state;
  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController targetRoleController;
  final TextEditingController preferredLocationController;
  final CandidateOnboardingProfile onboardingDraft;
  final VoidCallback onPickAvatar;
  final ValueChanged<String> onPreferredModalityChanged;
  final ValueChanged<String> onPreferredSeniorityChanged;
  final ValueChanged<bool> onWorkStyleSkippedChanged;
  final ValueChanged<String> onStartOfDayChanged;
  final ValueChanged<String> onFeedbackChanged;
  final ValueChanged<String> onStructureChanged;
  final ValueChanged<String> onTaskPaceChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final viewModel = ProfileFormLogic.buildViewModel(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(uiSpacing16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AppCard(
            padding: const EdgeInsets.all(uiSpacing24 + 4),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileAvatar(
                    avatarBytes: viewModel.avatarBytes,
                    avatarUrl: viewModel.avatarUrl,
                    onPickImage: onPickAvatar,
                  ),
                  const SizedBox(height: uiSpacing24),
                  const SectionHeader(
                    title: 'Tu perfil',
                    subtitle:
                        'Actualiza tus datos para que las empresas te encuentren.',
                    titleFontSize: 24,
                  ),
                  const SizedBox(height: uiSpacing24),
                  TextFormField(
                    controller: nameController,
                    validator: ProfileFormLogic.validateFirstName,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: uiSpacing16),
                  TextFormField(
                    controller: lastNameController,
                    validator: ProfileFormLogic.validateLastName,
                    decoration: const InputDecoration(
                      labelText: 'Apellidos',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: uiSpacing16),
                  TextFormField(
                    controller: emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      helperText: 'Este dato no se puede modificar.',
                    ),
                  ),
                  const SizedBox(height: uiSpacing24),
                  _OnboardingProfileEditor(
                    targetRoleController: targetRoleController,
                    preferredLocationController: preferredLocationController,
                    onboardingDraft: onboardingDraft,
                    onPreferredModalityChanged: onPreferredModalityChanged,
                    onPreferredSeniorityChanged: onPreferredSeniorityChanged,
                    onWorkStyleSkippedChanged: onWorkStyleSkippedChanged,
                    onStartOfDayChanged: onStartOfDayChanged,
                    onFeedbackChanged: onFeedbackChanged,
                    onStructureChanged: onStructureChanged,
                    onTaskPaceChanged: onTaskPaceChanged,
                  ),
                  const SizedBox(height: uiSpacing24),
                  FilledButton(
                    onPressed: viewModel.canSubmit ? onSubmit : null,
                    child: viewModel.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                uiWhite,
                              ),
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                  const SizedBox(height: uiSpacing16),
                  Text(
                    viewModel.sessionLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: uiMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingProfileEditor extends StatelessWidget {
  const _OnboardingProfileEditor({
    required this.targetRoleController,
    required this.preferredLocationController,
    required this.onboardingDraft,
    required this.onPreferredModalityChanged,
    required this.onPreferredSeniorityChanged,
    required this.onWorkStyleSkippedChanged,
    required this.onStartOfDayChanged,
    required this.onFeedbackChanged,
    required this.onStructureChanged,
    required this.onTaskPaceChanged,
  });

  final TextEditingController targetRoleController;
  final TextEditingController preferredLocationController;
  final CandidateOnboardingProfile onboardingDraft;
  final ValueChanged<String> onPreferredModalityChanged;
  final ValueChanged<String> onPreferredSeniorityChanged;
  final ValueChanged<bool> onWorkStyleSkippedChanged;
  final ValueChanged<String> onStartOfDayChanged;
  final ValueChanged<String> onFeedbackChanged;
  final ValueChanged<String> onStructureChanged;
  final ValueChanged<String> onTaskPaceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(uiSpacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(uiTileRadius),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferencias de matching',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: uiSpacing8),
          Text(
            'Puedes cambiarlas cuando quieras. Se usan para IA y filtros iniciales del dashboard.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: uiSpacing16),
          TextFormField(
            controller: targetRoleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Rol objetivo',
              hintText: 'Ej: Flutter Developer',
            ),
          ),
          const SizedBox(height: uiSpacing12),
          TextFormField(
            controller: preferredLocationController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Ubicación preferida',
              hintText: 'Ej: Madrid o remoto',
            ),
          ),
          const SizedBox(height: uiSpacing16),
          _SelectionChipSection(
            title: 'Modalidad',
            options: CandidateOnboardingPreferences.modalityOptions,
            selectedValue: onboardingDraft.preferredModality,
            onSelected: onPreferredModalityChanged,
          ),
          const SizedBox(height: uiSpacing16),
          _SelectionChipSection(
            title: 'Nivel de experiencia',
            options: CandidateOnboardingPreferences.seniorityOptions,
            selectedValue: onboardingDraft.preferredSeniority,
            onSelected: onPreferredSeniorityChanged,
          ),
          const SizedBox(height: uiSpacing8),
          SwitchListTile.adaptive(
            value: onboardingDraft.workStyleSkipped,
            onChanged: onWorkStyleSkippedChanged,
            contentPadding: EdgeInsets.zero,
            title: const Text('Omitir bloque de estilo de trabajo'),
            subtitle: const Text(
              'Si lo activas, no se usarán señales culturales en el matching.',
            ),
          ),
          if (!onboardingDraft.workStyleSkipped) ...[
            const SizedBox(height: uiSpacing4),
            CandidateOnboardingWorkStyleStep(
              startOfDayPreference: onboardingDraft.startOfDayPreference ?? '',
              feedbackPreference: onboardingDraft.feedbackPreference ?? '',
              structurePreference: onboardingDraft.structurePreference ?? '',
              taskPacePreference: onboardingDraft.taskPacePreference ?? '',
              onStartOfDayChanged: onStartOfDayChanged,
              onFeedbackChanged: onFeedbackChanged,
              onStructureChanged: onStructureChanged,
              onTaskPaceChanged: onTaskPaceChanged,
            ),
          ],
        ],
      ),
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
