import 'package:flutter/material.dart';

import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
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
    required this.onPickAvatar,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final ProfileFormState state;
  final TextEditingController nameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final VoidCallback onPickAvatar;
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
