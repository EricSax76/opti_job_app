import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    const background = Color(0xFFF8FAFC);
    const ink = Color(0xFF0F172A);
    const muted = Color(0xFF475569);
    const border = Color(0xFFE2E8F0);

    final company = context.watch<CompanyAuthCubit>().state.company;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: border, width: 1)),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                                    backgroundColor: background,
                                    backgroundImage: avatarImage,
                                    child: avatarImage == null
                                        ? const Icon(
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
                                      borderRadius: BorderRadius.circular(18),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: ink,
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
                              decoration: InputDecoration(
                                labelText: 'Nombre',
                                filled: true,
                                fillColor: background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: border),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: company.email,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Correo',
                                helperText: 'Este dato no se puede modificar.',
                                filled: true,
                                fillColor: background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: border),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: ink,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: state.canSubmit
                                    ? () => context
                                        .read<CompanyProfileFormCubit>()
                                        .submit()
                                    : null,
                                child: state.isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
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
