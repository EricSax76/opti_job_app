import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileAvatar(
                      avatarBytes: state.avatarBytes,
                      avatarUrl: state.avatarUrl,
                      onPickImage: formCubit.pickAvatar,
                    ),
                    const SizedBox(height: 20),
                    const _ProfileHeader(),
                    const SizedBox(height: 20),
                    _ProfileTextField(
                      controller: formCubit.nameController,
                      label: 'Nombre',
                    ),
                    const SizedBox(height: 12),
                    _ProfileTextField(
                      controller: formCubit.lastNameController,
                      label: 'Apellidos',
                    ),
                    const SizedBox(height: 12),
                    _ProfileTextField(
                      controller: formCubit.emailController,
                      label: 'Correo electrónico',
                      helperText: 'Este dato no se puede modificar.',
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    _SaveButton(
                      onPressed: state.canSubmit ? formCubit.submit : null,
                      isSaving: state.isSaving,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sesión activa como ${state.candidateName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF475569),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    const inkColor = Color(0xFF0F172A);
    const mutedColor = Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu perfil',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Actualiza tus datos para que las empresas te encuentren.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: mutedColor),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.label,
    this.helperText,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8FAFC);
    const borderColor = Color(0xFFE2E8F0);
    const accentColor = Color(0xFF3FA7A0);

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onPressed, required this.isSaving});

  final VoidCallback? onPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    const inkColor = Color(0xFF0F172A);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: inkColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onPressed,
        child: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Guardar cambios'),
      ),
    );
  }
}
