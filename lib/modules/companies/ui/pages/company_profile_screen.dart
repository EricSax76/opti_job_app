import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/companies/cubits/company_profile_form_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_avatar_picker.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_profile_form_fields.dart';
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
    final border = colorScheme.outline;
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
                  context.read<CompanyProfileFormCubit>().clearNotice();
                }
              },
              builder: (context, state) {
                final cubit = context.read<CompanyProfileFormCubit>();

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
                            CompanyAvatarPicker(
                              avatarUrl: state.company?.avatarUrl,
                              avatarBytes: state.avatarBytes,
                              onPickAvatar: cubit.pickAvatar,
                            ),
                            const SizedBox(height: 20),
                            CompanyProfileFormFields(
                              nameController: cubit.nameController,
                              email: company.email,
                              canSubmit: state.canSubmit,
                              isSaving: state.isSaving,
                              onSubmit: cubit.submit,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sesión activa como ${company.name}',
                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
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
