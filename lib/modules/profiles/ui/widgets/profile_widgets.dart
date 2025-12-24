import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/profiles/cubit/profile_cubit.dart';
import 'package:opti_job_app/modules/profiles/cubit/profile_form_cubit.dart';

const _profileBackground = Color(0xFFF8FAFC);
const _profileInk = Color(0xFF0F172A);
const _profileMuted = Color(0xFF475569);
const _profileBorder = Color(0xFFE2E8F0);
const _profileAccent = Color(0xFF3FA7A0);

class CandidateProfileView extends StatelessWidget {
  const CandidateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileFormCubit(profileCubit: context.read<ProfileCubit>()),
      child: const _CandidateProfileContent(),
    );
  }
}

class _CandidateProfileContent extends StatelessWidget {
  const _CandidateProfileContent();

  @override
  Widget build(BuildContext context) {
    final formCubit = context.read<ProfileFormCubit>();

    return BlocConsumer<ProfileFormCubit, ProfileFormState>(
      listener: (context, state) {
        if (state.notice != null && state.noticeMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.noticeMessage!)),
          );
          context.read<ProfileFormCubit>().clearNotice();
        }
      },
      builder: (context, state) {
        if (state.viewStatus == ProfileFormViewStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.viewStatus == ProfileFormViewStatus.error) {
          return _ProfileStateMessage(
            title: 'No pudimos cargar tu perfil',
            message: state.errorMessage ?? 'Intenta nuevamente en unos segundos.',
            actionLabel: 'Reintentar',
            onAction: formCubit.refresh,
          );
        }

        if (state.viewStatus == ProfileFormViewStatus.empty) {
          return const _ProfileStateMessage(
            title: 'Inicia sesión para ver tu perfil',
            message: 'Necesitas una cuenta activa para editar tu información.',
          );
        }

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
                  border: Border.all(color: _profileBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              final ImageProvider? avatarImage;
                              if (state.avatarBytes != null) {
                                avatarImage = MemoryImage(state.avatarBytes!);
                              } else if (state.avatarUrl != null &&
                                  state.avatarUrl!.isNotEmpty) {
                                avatarImage = NetworkImage(state.avatarUrl!);
                              } else {
                                avatarImage = null;
                              }
                              return CircleAvatar(
                                radius: 44,
                                backgroundColor: _profileBackground,
                                backgroundImage: avatarImage,
                                child: avatarImage == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: _profileMuted,
                                      )
                                    : null,
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: formCubit.pickAvatar,
                              borderRadius: BorderRadius.circular(18),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: _profileInk,
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu perfil',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _profileInk,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Actualiza tus datos para que las empresas te encuentren.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _profileMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: formCubit.nameController,
                      decoration: _inputDecoration(
                        labelText: 'Nombre',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: formCubit.lastNameController,
                      decoration: _inputDecoration(
                        labelText: 'Apellidos',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: formCubit.emailController,
                      readOnly: true,
                      decoration: _inputDecoration(
                        labelText: 'Correo electrónico',
                        helperText: 'Este dato no se puede modificar.',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _profileInk,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: state.canSubmit ? formCubit.submit : null,
                        child: state.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sesión activa como ${state.candidateName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _profileMuted,
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

InputDecoration _inputDecoration({
  required String labelText,
  String? helperText,
}) {
  return InputDecoration(
    labelText: labelText,
    helperText: helperText,
    filled: true,
    fillColor: _profileBackground,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _profileBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _profileBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _profileAccent),
    ),
  );
}

class _ProfileStateMessage extends StatelessWidget {
  const _ProfileStateMessage({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _profileMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
