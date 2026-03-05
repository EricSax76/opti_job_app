import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:opti_job_app/core/theme/ui_tokens.dart';

import 'package:opti_job_app/modules/companies/ui/widgets/company_avatar_picker.dart';
import 'package:opti_job_app/modules/companies/ui/widgets/company_profile_form_fields.dart';

class CompanyProfileFormCard extends StatelessWidget {
  const CompanyProfileFormCard({
    super.key,
    this.avatarUrl,
    this.avatarBytes,
    required this.onPickAvatar,
    required this.nameController,
    required this.websiteController,
    required this.industryController,
    required this.teamSizeController,
    required this.headquartersController,
    required this.descriptionController,
    required this.controllerLegalNameController,
    required this.controllerTaxIdController,
    required this.privacyContactEmailController,
    required this.dpoNameController,
    required this.dpoEmailController,
    required this.privacyPolicyUrlController,
    required this.retentionPolicySummaryController,
    required this.internationalTransfersSummaryController,
    required this.aiConsentTextVersionController,
    required this.aiConsentTextController,
    required this.email,
    required this.complianceComplete,
    required this.enabledMultipostingChannels,
    required this.onChannelToggle,
    required this.canSubmit,
    required this.isSaving,
    required this.onSubmit,
    required this.sessionCompanyName,
    required this.surfaceColor,
    required this.borderColor,
    required this.mutedTextColor,
  });

  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final VoidCallback onPickAvatar;
  final TextEditingController nameController;
  final TextEditingController websiteController;
  final TextEditingController industryController;
  final TextEditingController teamSizeController;
  final TextEditingController headquartersController;
  final TextEditingController descriptionController;
  final TextEditingController controllerLegalNameController;
  final TextEditingController controllerTaxIdController;
  final TextEditingController privacyContactEmailController;
  final TextEditingController dpoNameController;
  final TextEditingController dpoEmailController;
  final TextEditingController privacyPolicyUrlController;
  final TextEditingController retentionPolicySummaryController;
  final TextEditingController internationalTransfersSummaryController;
  final TextEditingController aiConsentTextVersionController;
  final TextEditingController aiConsentTextController;
  final String email;
  final bool complianceComplete;
  final List<String> enabledMultipostingChannels;
  final void Function(String channelId, bool enabled) onChannelToggle;
  final bool canSubmit;
  final bool isSaving;
  final VoidCallback onSubmit;
  final String sessionCompanyName;
  final Color surfaceColor;
  final Color borderColor;
  final Color mutedTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(uiCardRadius),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CompanyAvatarPicker(
                  avatarUrl: avatarUrl,
                  avatarBytes: avatarBytes,
                  onPickAvatar: onPickAvatar,
                ),
                const SizedBox(height: 20),
                CompanyProfileFormFields(
                  nameController: nameController,
                  websiteController: websiteController,
                  industryController: industryController,
                  teamSizeController: teamSizeController,
                  headquartersController: headquartersController,
                  descriptionController: descriptionController,
                  controllerLegalNameController: controllerLegalNameController,
                  controllerTaxIdController: controllerTaxIdController,
                  privacyContactEmailController: privacyContactEmailController,
                  dpoNameController: dpoNameController,
                  dpoEmailController: dpoEmailController,
                  privacyPolicyUrlController: privacyPolicyUrlController,
                  retentionPolicySummaryController:
                      retentionPolicySummaryController,
                  internationalTransfersSummaryController:
                      internationalTransfersSummaryController,
                  aiConsentTextVersionController:
                      aiConsentTextVersionController,
                  aiConsentTextController: aiConsentTextController,
                  email: email,
                  complianceComplete: complianceComplete,
                  enabledMultipostingChannels: enabledMultipostingChannels,
                  onChannelToggle: onChannelToggle,
                  canSubmit: canSubmit,
                  isSaving: isSaving,
                  onSubmit: onSubmit,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sesión activa como $sessionCompanyName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
