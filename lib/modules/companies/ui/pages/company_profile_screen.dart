import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:opti_job_app/modules/companies/cubits/company_profile_form_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_profile_form_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_account_avatar_menu.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/profile/company_profile_app_bar.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/profile/company_profile_empty_state.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/profile/company_profile_form_card.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key, required this.cubit});

  final CompanyProfileFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    return _CompanyProfileView(cubit: cubit);
  }
}

class _CompanyProfileView extends StatelessWidget {
  const _CompanyProfileView({required this.cubit});

  final CompanyProfileFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    // ...
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CompanyProfileAppBar(
          showActions: context.watch<CompanyAuthCubit>().state.company != null,
          showLogoutAction: kIsWeb,
          onLogout: () => context.read<CompanyAuthCubit>().logout(),
          accountMenu: const CompanyAccountAvatarMenu(showProfileOption: false),
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outline;
    final surfaceColor = theme.cardTheme.color ?? colorScheme.surface;
    final mutedTextColor = colorScheme.onSurfaceVariant;

    final company = context.watch<CompanyAuthCubit>().state.company;
    if (company == null) return const CompanyProfileEmptyState();

    return BlocConsumer<CompanyProfileFormCubit, CompanyProfileFormState>(
      bloc: cubit,
      listener: _handleProfileFormNotice,
      builder: (context, state) {
        return CompanyProfileFormCard(
          avatarUrl: state.company?.avatarUrl,
          avatarBytes: state.avatarBytes,
          onPickAvatar: cubit.pickAvatar,
          nameController: cubit.nameController,
          websiteController: cubit.websiteController,
          industryController: cubit.industryController,
          teamSizeController: cubit.teamSizeController,
          headquartersController: cubit.headquartersController,
          descriptionController: cubit.descriptionController,
          controllerLegalNameController: cubit.controllerLegalNameController,
          controllerTaxIdController: cubit.controllerTaxIdController,
          privacyContactEmailController: cubit.privacyContactEmailController,
          dpoNameController: cubit.dpoNameController,
          dpoEmailController: cubit.dpoEmailController,
          privacyPolicyUrlController: cubit.privacyPolicyUrlController,
          retentionPolicySummaryController:
              cubit.retentionPolicySummaryController,
          internationalTransfersSummaryController:
              cubit.internationalTransfersSummaryController,
          aiConsentTextVersionController: cubit.aiConsentTextVersionController,
          aiConsentTextController: cubit.aiConsentTextController,
          email: company.email,
          complianceComplete: company.complianceProfile.isComplete,
          enabledMultipostingChannels: state.enabledMultipostingChannels,
          onChannelToggle: cubit.toggleMultipostingChannel,
          canSubmit: state.canSubmit,
          isSaving: state.isSaving,
          onSubmit: cubit.submit,
          sessionCompanyName: company.name,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          mutedTextColor: mutedTextColor,
        );
      },
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
