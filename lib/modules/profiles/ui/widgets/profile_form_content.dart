import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';
import 'package:opti_job_app/core/widgets/app_card.dart';
import 'package:opti_job_app/core/widgets/section_header.dart';
import 'package:opti_job_app/modules/profiles/cubits/profile_form_cubit.dart';
import 'package:opti_job_app/modules/profiles/ui/widgets/profile_avatar.dart';

class ProfileFormContent extends StatelessWidget {
  const ProfileFormContent({super.key});

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<ProfileFormCubit>();

    return BlocBuilder<ProfileFormCubit, ProfileFormState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(uiSpacing16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                padding: const EdgeInsets.all(uiSpacing24 + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileAvatar(
                      avatarBytes: state.avatarBytes,
                      avatarUrl: state.avatarUrl,
                      onPickImage: formCubit.pickAvatar,
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
                      controller: formCubit.nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: uiSpacing16),
                    TextFormField(
                      controller: formCubit.lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: uiSpacing16),
                    TextFormField(
                      controller: formCubit.emailController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        helperText: 'Este dato no se puede modificar.',
                      ),
                    ),
                    const SizedBox(height: uiSpacing24),
                    FilledButton(
                      onPressed: state.canSubmit ? formCubit.submit : null,
                      child: state.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(uiWhite),
                              ),
                            )
                          : const Text('Guardar cambios'),
                    ),
                    const SizedBox(height: uiSpacing16),
                    Text(
                      'Sesión activa como ${state.candidateName}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: uiMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

