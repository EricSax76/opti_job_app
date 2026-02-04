import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/companies/cubits/company_profile_form_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CompanyProfileFormCubit(
        profileRepository: context.read<ProfileRepository>(),
        companyAuthCubit: context.read<CompanyAuthCubit>(),
      ),
      child: const _CompanyProfileView(),
    );
  }
}

class _CompanyProfileView extends StatelessWidget {
  const _CompanyProfileView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? colorScheme.surface;
    final surfaceContainer = colorScheme.surfaceContainerHighest;
    final border = colorScheme.outline;
    final ink = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;

    final company = context.watch<CompanyAuthCubit>().state.company;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: border, width: 1)),
        actions: company != null
            ? [
                const CompanyAccountAvatarMenu(showProfileOption: false),
                if (kIsWeb)
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () => context.read<CompanyAuthCubit>().logout(),
                    icon: const Icon(Icons.logout),
                  ),
              ]
            : null,
      ),
      body: company == null
          ? const Center(child: Text('Inicia sesión para ver tu perfil.'))
          : BlocConsumer<CompanyProfileFormCubit, CompanyProfileFormState>(
              listener: (context, state) {
                if (state.notice != null && state.noticeMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.noticeMessage!)),
                  );
                  context.read<CompanyProfileFormCubit>().clearNotice();
                }
              },
              builder: (context, state) {
                final avatarUrl = state.company?.avatarUrl;
                final avatarBytes = state.avatarBytes;
                ImageProvider? avatarImage;
                if (avatarBytes != null) {
                  avatarImage = MemoryImage(avatarBytes);
                } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
                  avatarImage = NetworkImage(avatarUrl);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(uiCardRadius),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: surfaceContainer,
                                    backgroundImage: avatarImage,
                                    child: avatarImage == null
                                        ? Icon(
                                            Icons.business_outlined,
                                            size: 40,
                                            color: muted,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: InkWell(
                                      onTap: context
                                          .read<CompanyProfileFormCubit>()
                                          .pickAvatar,
                                      borderRadius: BorderRadius.circular(uiTileRadius),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: colorScheme.primary,
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Datos de la empresa',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ink,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: context
                                  .read<CompanyProfileFormCubit>()
                                  .nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: company.email,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Correo',
                                helperText: 'Este dato no se puede modificar.',
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: state.canSubmit
                                    ? () => context
                                        .read<CompanyProfileFormCubit>()
                                        .submit()
                                    : null,
                                child: state.isSaving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            colorScheme.onPrimary,
                                          ),
                                        ),
                                      )
                                    : const Text('Guardar cambios'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sesión activa como ${company.name}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
