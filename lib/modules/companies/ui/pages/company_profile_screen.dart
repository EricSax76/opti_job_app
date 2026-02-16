import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/companies/cubits/company_profile_form_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/profile/company_profile_app_bar.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/profile/company_profile_empty_state.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/profile/company_profile_form_card.dart';
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
    final borderColor = colorScheme.outline;
    final surfaceColor = theme.cardTheme.color ?? colorScheme.surface;
    final mutedTextColor = colorScheme.onSurfaceVariant;

    final company = context.watch<CompanyAuthCubit>().state.company;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CompanyProfileAppBar(
        borderColor: borderColor,
        showActions: company != null,
        showLogoutAction: kIsWeb,
        onLogout: () => context.read<CompanyAuthCubit>().logout(),
        accountMenu: const CompanyAccountAvatarMenu(showProfileOption: false),
      ),
      body: company == null
          ? const CompanyProfileEmptyState()
          : BlocConsumer<CompanyProfileFormCubit, CompanyProfileFormState>(
              listener: _handleProfileFormNotice,
              builder: (context, state) {
                final cubit = context.read<CompanyProfileFormCubit>();
                return CompanyProfileFormCard(
                  avatarUrl: state.company?.avatarUrl,
                  avatarBytes: state.avatarBytes,
                  onPickAvatar: cubit.pickAvatar,
                  nameController: cubit.nameController,
                  email: company.email,
                  canSubmit: state.canSubmit,
                  isSaving: state.isSaving,
                  onSubmit: cubit.submit,
                  sessionCompanyName: company.name,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  mutedTextColor: mutedTextColor,
                );
              },
            ),
    );
  }

  void _handleProfileFormNotice(
    BuildContext context,
    CompanyProfileFormState state,
  ) {
    if (state.notice == null || state.noticeMessage == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.noticeMessage!)));
    context.read<CompanyProfileFormCubit>().clearNotice();
  }
}
