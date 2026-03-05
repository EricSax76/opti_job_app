import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_profile_form_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/companies/models/company_compliance_profile.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class CompanyProfileFormCubit extends Cubit<CompanyProfileFormState> {
  CompanyProfileFormCubit({
    required ProfileRepository profileRepository,
    required CompanyAuthCubit companyAuthCubit,
  }) : _profileRepository = profileRepository,
       _companyAuthCubit = companyAuthCubit,
       nameController = TextEditingController(),
       websiteController = TextEditingController(),
       industryController = TextEditingController(),
       teamSizeController = TextEditingController(),
       headquartersController = TextEditingController(),
       descriptionController = TextEditingController(),
       controllerLegalNameController = TextEditingController(),
       controllerTaxIdController = TextEditingController(),
       privacyContactEmailController = TextEditingController(),
       dpoNameController = TextEditingController(),
       dpoEmailController = TextEditingController(),
       privacyPolicyUrlController = TextEditingController(),
       retentionPolicySummaryController = TextEditingController(),
       internationalTransfersSummaryController = TextEditingController(),
       aiConsentTextVersionController = TextEditingController(),
       aiConsentTextController = TextEditingController(),
       super(
         const CompanyProfileFormState(
           enabledMultipostingChannels: companyDefaultMultipostingChannels,
         ),
       ) {
    nameController.addListener(_handleTextChanged);
    websiteController.addListener(_handleTextChanged);
    industryController.addListener(_handleTextChanged);
    teamSizeController.addListener(_handleTextChanged);
    headquartersController.addListener(_handleTextChanged);
    descriptionController.addListener(_handleTextChanged);
    controllerLegalNameController.addListener(_handleTextChanged);
    controllerTaxIdController.addListener(_handleTextChanged);
    privacyContactEmailController.addListener(_handleTextChanged);
    dpoNameController.addListener(_handleTextChanged);
    dpoEmailController.addListener(_handleTextChanged);
    privacyPolicyUrlController.addListener(_handleTextChanged);
    retentionPolicySummaryController.addListener(_handleTextChanged);
    internationalTransfersSummaryController.addListener(_handleTextChanged);
    aiConsentTextVersionController.addListener(_handleTextChanged);
    aiConsentTextController.addListener(_handleTextChanged);

    _syncWithAuthenticatedCompany(
      company: _companyAuthCubit.state.company,
      preserveDraftForSameCompany: false,
    );
    _companyAuthSubscription = _companyAuthCubit.stream.listen((authState) {
      _syncWithAuthenticatedCompany(
        company: authState.company,
        preserveDraftForSameCompany: true,
      );
    });
  }

  final ProfileRepository _profileRepository;
  final CompanyAuthCubit _companyAuthCubit;
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
  late final StreamSubscription<CompanyAuthState> _companyAuthSubscription;

  String _initialName = '';
  String _initialWebsite = '';
  String _initialIndustry = '';
  String _initialTeamSize = '';
  String _initialHeadquarters = '';
  String _initialDescription = '';
  String _initialControllerLegalName = '';
  String _initialControllerTaxId = '';
  String _initialPrivacyContactEmail = '';
  String _initialDpoName = '';
  String _initialDpoEmail = '';
  String _initialPrivacyPolicyUrl = '';
  String _initialRetentionPolicySummary = '';
  String _initialInternationalTransfersSummary = '';
  String _initialAiConsentTextVersion = '';
  String _initialAiConsentText = '';
  List<String> _initialEnabledChannels = companyDefaultMultipostingChannels;

  var _isSyncingControllerFromState = false;

  void clearNotice() {
    if (state.notice != null) {
      emit(state.copyWith(clearNotice: true));
    }
  }

  void toggleMultipostingChannel(String channelId, bool enabled) {
    final normalizedId = _normalizeChannelId(channelId);
    if (normalizedId == null) return;

    final next = {...state.enabledMultipostingChannels};
    if (enabled) {
      next.add(normalizedId);
    } else {
      next.remove(normalizedId);
    }

    final nextChannels = _sortChannels(next.toList(growable: false));
    _emitDraftState(enabledChannels: nextChannels);
  }

  Future<void> pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      _emitDraftState(avatarBytes: bytes);
    } catch (_) {
      emit(
        state.copyWith(
          notice: CompanyProfileFormNotice.error,
          noticeMessage: 'No se pudo seleccionar la imagen.',
        ),
      );
    }
  }

  Future<void> submit() async {
    final company = _companyAuthCubit.state.company;
    if (company == null) {
      emit(
        state.copyWith(
          notice: CompanyProfileFormNotice.error,
          noticeMessage: 'No hay una empresa autenticada.',
        ),
      );
      return;
    }

    final name = nameController.text.trim();
    final website = websiteController.text.trim();
    final industry = industryController.text.trim();
    final teamSize = teamSizeController.text.trim();
    final headquarters = headquartersController.text.trim();
    final description = descriptionController.text.trim();
    final controllerLegalName = controllerLegalNameController.text.trim();
    final controllerTaxId = controllerTaxIdController.text.trim();
    final privacyContactEmail = privacyContactEmailController.text.trim();
    final dpoName = dpoNameController.text.trim();
    final dpoEmail = dpoEmailController.text.trim();
    final privacyPolicyUrl = privacyPolicyUrlController.text.trim();
    final retentionPolicySummary = retentionPolicySummaryController.text.trim();
    final internationalTransfersSummary =
        internationalTransfersSummaryController.text.trim();
    final aiConsentTextVersion = aiConsentTextVersionController.text.trim();
    final aiConsentText = aiConsentTextController.text.trim();
    final enabledChannels = _sortChannels(state.enabledMultipostingChannels);

    if (name.isEmpty || !state.canSubmit || !state.hasChanges) return;

    if (privacyContactEmail.isNotEmpty && !_isValidEmail(privacyContactEmail)) {
      emit(
        state.copyWith(
          notice: CompanyProfileFormNotice.error,
          noticeMessage: 'El correo de privacidad no tiene un formato válido.',
        ),
      );
      return;
    }

    if (dpoEmail.isNotEmpty && !_isValidEmail(dpoEmail)) {
      emit(
        state.copyWith(
          notice: CompanyProfileFormNotice.error,
          noticeMessage:
              'El correo del encargado/DPO no tiene un formato válido.',
        ),
      );
      return;
    }

    final complianceProfile = CompanyComplianceProfile(
      controllerLegalName: controllerLegalName,
      controllerTaxId: controllerTaxId,
      privacyContactEmail: privacyContactEmail,
      dpoName: dpoName,
      dpoEmail: dpoEmail,
      privacyPolicyUrl: privacyPolicyUrl,
      retentionPolicySummary: retentionPolicySummary,
      internationalTransfersSummary: internationalTransfersSummary,
      aiConsentTextVersion: aiConsentTextVersion.isEmpty
          ? '2026.04'
          : aiConsentTextVersion,
      aiConsentText: aiConsentText,
    );

    emit(state.copyWith(isSaving: true, canSubmit: false));
    try {
      final updatedCompany = await _profileRepository.updateCompanyProfile(
        uid: company.uid,
        name: name,
        website: website,
        industry: industry,
        teamSize: teamSize,
        headquarters: headquarters,
        description: description,
        multipostingSettings: CompanyMultipostingSettings(
          enabledChannels: enabledChannels,
          costOverridesEur: company.multipostingSettings.costOverridesEur,
        ),
        complianceProfile: complianceProfile,
        avatarBytes: state.avatarBytes,
      );

      final mergedCompany = Company(
        id: updatedCompany.id,
        name: updatedCompany.name,
        email: updatedCompany.email,
        uid: updatedCompany.uid,
        role: updatedCompany.role,
        onboardingCompleted: company.onboardingCompleted,
        website: updatedCompany.website,
        industry: updatedCompany.industry,
        teamSize: updatedCompany.teamSize,
        headquarters: updatedCompany.headquarters,
        description: updatedCompany.description,
        multipostingSettings: updatedCompany.multipostingSettings,
        complianceProfile: updatedCompany.complianceProfile,
        token: company.token,
        avatarUrl: updatedCompany.avatarUrl,
      );

      _companyAuthCubit.updateCompany(mergedCompany);
      _syncInitialFields(mergedCompany);
      _setControllersFromCompany(mergedCompany);

      emit(
        state.copyWith(
          company: mergedCompany,
          enabledMultipostingChannels:
              mergedCompany.multipostingSettings.enabledChannels,
          clearAvatarBytes: true,
          hasChanges: false,
          canSubmit: false,
          isSaving: false,
          notice: CompanyProfileFormNotice.success,
          noticeMessage: 'Perfil actualizado.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          canSubmit: _canSubmit(
            hasChanges: state.hasChanges,
            isSaving: false,
            name: nameController.text.trim(),
          ),
          notice: CompanyProfileFormNotice.error,
          noticeMessage: 'No se pudo actualizar el perfil.',
        ),
      );
    }
  }

  void _handleTextChanged() {
    if (_isSyncingControllerFromState) return;
    _emitDraftState();
  }

  void _emitDraftState({
    Uint8List? avatarBytes,
    List<String>? enabledChannels,
  }) {
    final nextAvatarBytes = avatarBytes ?? state.avatarBytes;
    final nextChannels = enabledChannels ?? state.enabledMultipostingChannels;
    final hasChanges = _computeHasChanges(
      name: nameController.text.trim(),
      website: websiteController.text.trim(),
      industry: industryController.text.trim(),
      teamSize: teamSizeController.text.trim(),
      headquarters: headquartersController.text.trim(),
      description: descriptionController.text.trim(),
      controllerLegalName: controllerLegalNameController.text.trim(),
      controllerTaxId: controllerTaxIdController.text.trim(),
      privacyContactEmail: privacyContactEmailController.text.trim(),
      dpoName: dpoNameController.text.trim(),
      dpoEmail: dpoEmailController.text.trim(),
      privacyPolicyUrl: privacyPolicyUrlController.text.trim(),
      retentionPolicySummary: retentionPolicySummaryController.text.trim(),
      internationalTransfersSummary: internationalTransfersSummaryController
          .text
          .trim(),
      aiConsentTextVersion: aiConsentTextVersionController.text.trim(),
      aiConsentText: aiConsentTextController.text.trim(),
      avatarBytes: nextAvatarBytes,
      enabledChannels: nextChannels,
    );
    final canSubmit = _canSubmit(
      hasChanges: hasChanges,
      isSaving: state.isSaving,
      name: nameController.text.trim(),
    );

    emit(
      state.copyWith(
        avatarBytes: nextAvatarBytes,
        enabledMultipostingChannels: nextChannels,
        hasChanges: hasChanges,
        canSubmit: canSubmit,
      ),
    );
  }

  bool _computeHasChanges({
    required String name,
    required String website,
    required String industry,
    required String teamSize,
    required String headquarters,
    required String description,
    required String controllerLegalName,
    required String controllerTaxId,
    required String privacyContactEmail,
    required String dpoName,
    required String dpoEmail,
    required String privacyPolicyUrl,
    required String retentionPolicySummary,
    required String internationalTransfersSummary,
    required String aiConsentTextVersion,
    required String aiConsentText,
    required Uint8List? avatarBytes,
    required List<String> enabledChannels,
  }) {
    final nameChanged = name != _initialName;
    final websiteChanged = website != _initialWebsite;
    final industryChanged = industry != _initialIndustry;
    final teamSizeChanged = teamSize != _initialTeamSize;
    final headquartersChanged = headquarters != _initialHeadquarters;
    final descriptionChanged = description != _initialDescription;
    final controllerLegalNameChanged =
        controllerLegalName != _initialControllerLegalName;
    final controllerTaxIdChanged = controllerTaxId != _initialControllerTaxId;
    final privacyContactEmailChanged =
        privacyContactEmail != _initialPrivacyContactEmail;
    final dpoNameChanged = dpoName != _initialDpoName;
    final dpoEmailChanged = dpoEmail != _initialDpoEmail;
    final privacyPolicyUrlChanged =
        privacyPolicyUrl != _initialPrivacyPolicyUrl;
    final retentionPolicySummaryChanged =
        retentionPolicySummary != _initialRetentionPolicySummary;
    final internationalTransfersSummaryChanged =
        internationalTransfersSummary != _initialInternationalTransfersSummary;
    final aiConsentTextVersionChanged =
        aiConsentTextVersion != _initialAiConsentTextVersion;
    final aiConsentTextChanged = aiConsentText != _initialAiConsentText;
    final avatarChanged = avatarBytes != null;
    final channelsChanged =
        _sortChannels(enabledChannels) !=
        _sortChannels(_initialEnabledChannels);

    return nameChanged ||
        websiteChanged ||
        industryChanged ||
        teamSizeChanged ||
        headquartersChanged ||
        descriptionChanged ||
        controllerLegalNameChanged ||
        controllerTaxIdChanged ||
        privacyContactEmailChanged ||
        dpoNameChanged ||
        dpoEmailChanged ||
        privacyPolicyUrlChanged ||
        retentionPolicySummaryChanged ||
        internationalTransfersSummaryChanged ||
        aiConsentTextVersionChanged ||
        aiConsentTextChanged ||
        avatarChanged ||
        channelsChanged;
  }

  bool _canSubmit({
    required bool hasChanges,
    required bool isSaving,
    required String name,
  }) {
    return hasChanges && !isSaving && name.isNotEmpty;
  }

  void _syncWithAuthenticatedCompany({
    required Company? company,
    required bool preserveDraftForSameCompany,
  }) {
    final previousCompany = state.company;
    if (_sameCompany(previousCompany, company)) return;

    if (company == null) {
      _syncInitialFields(null);
      _setControllersFromCompany(null);
      emit(
        state.copyWith(
          clearCompany: true,
          clearAvatarBytes: true,
          enabledMultipostingChannels: companyDefaultMultipostingChannels,
          hasChanges: false,
          canSubmit: false,
          isSaving: false,
          clearNotice: true,
        ),
      );
      return;
    }

    final sameCompanyUid =
        previousCompany != null && previousCompany.uid == company.uid;
    if (preserveDraftForSameCompany && sameCompanyUid && state.hasChanges) {
      emit(state.copyWith(company: company));
      return;
    }

    _syncInitialFields(company);
    _setControllersFromCompany(company);
    emit(
      state.copyWith(
        company: company,
        enabledMultipostingChannels:
            company.multipostingSettings.enabledChannels,
        clearAvatarBytes: true,
        hasChanges: false,
        canSubmit: false,
        isSaving: false,
        clearNotice: true,
      ),
    );
  }

  void _syncInitialFields(Company? company) {
    _initialName = company?.name.trim() ?? '';
    _initialWebsite = company?.website.trim() ?? '';
    _initialIndustry = company?.industry.trim() ?? '';
    _initialTeamSize = company?.teamSize.trim() ?? '';
    _initialHeadquarters = company?.headquarters.trim() ?? '';
    _initialDescription = company?.description.trim() ?? '';
    _initialControllerLegalName =
        company?.complianceProfile.controllerLegalName.trim() ?? '';
    _initialControllerTaxId =
        company?.complianceProfile.controllerTaxId.trim() ?? '';
    _initialPrivacyContactEmail =
        company?.complianceProfile.privacyContactEmail.trim() ?? '';
    _initialDpoName = company?.complianceProfile.dpoName.trim() ?? '';
    _initialDpoEmail = company?.complianceProfile.dpoEmail.trim() ?? '';
    _initialPrivacyPolicyUrl =
        company?.complianceProfile.privacyPolicyUrl.trim() ?? '';
    _initialRetentionPolicySummary =
        company?.complianceProfile.retentionPolicySummary.trim() ?? '';
    _initialInternationalTransfersSummary =
        company?.complianceProfile.internationalTransfersSummary.trim() ?? '';
    _initialAiConsentTextVersion =
        company?.complianceProfile.aiConsentTextVersion.trim() ?? '';
    _initialAiConsentText =
        company?.complianceProfile.aiConsentText.trim() ?? '';

    _initialEnabledChannels = company == null
        ? companyDefaultMultipostingChannels
        : _sortChannels(company.multipostingSettings.enabledChannels);
  }

  void _setControllersFromCompany(Company? company) {
    _setControllerText(nameController, company?.name ?? '');
    _setControllerText(websiteController, company?.website ?? '');
    _setControllerText(industryController, company?.industry ?? '');
    _setControllerText(teamSizeController, company?.teamSize ?? '');
    _setControllerText(headquartersController, company?.headquarters ?? '');
    _setControllerText(descriptionController, company?.description ?? '');
    _setControllerText(
      controllerLegalNameController,
      company?.complianceProfile.controllerLegalName ?? '',
    );
    _setControllerText(
      controllerTaxIdController,
      company?.complianceProfile.controllerTaxId ?? '',
    );
    _setControllerText(
      privacyContactEmailController,
      company?.complianceProfile.privacyContactEmail ?? '',
    );
    _setControllerText(
      dpoNameController,
      company?.complianceProfile.dpoName ?? '',
    );
    _setControllerText(
      dpoEmailController,
      company?.complianceProfile.dpoEmail ?? '',
    );
    _setControllerText(
      privacyPolicyUrlController,
      company?.complianceProfile.privacyPolicyUrl ?? '',
    );
    _setControllerText(
      retentionPolicySummaryController,
      company?.complianceProfile.retentionPolicySummary ?? '',
    );
    _setControllerText(
      internationalTransfersSummaryController,
      company?.complianceProfile.internationalTransfersSummary ?? '',
    );
    _setControllerText(
      aiConsentTextVersionController,
      company?.complianceProfile.aiConsentTextVersion ?? '',
    );
    _setControllerText(
      aiConsentTextController,
      company?.complianceProfile.aiConsentText ?? '',
    );
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    _isSyncingControllerFromState = true;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
    _isSyncingControllerFromState = false;
  }

  bool _sameCompany(Company? a, Company? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.id == b.id &&
        a.uid == b.uid &&
        a.name == b.name &&
        a.email == b.email &&
        a.role == b.role &&
        a.onboardingCompleted == b.onboardingCompleted &&
        a.website == b.website &&
        a.industry == b.industry &&
        a.teamSize == b.teamSize &&
        a.headquarters == b.headquarters &&
        a.description == b.description &&
        a.multipostingSettings == b.multipostingSettings &&
        a.complianceProfile == b.complianceProfile &&
        a.token == b.token &&
        a.avatarUrl == b.avatarUrl;
  }

  List<String> _sortChannels(List<String> channels) {
    final normalized = <String>{};
    for (final raw in channels) {
      final channelId = _normalizeChannelId(raw);
      if (channelId != null) {
        normalized.add(channelId);
      }
    }

    final order = companyMultipostingChannelCatalog
        .map((channel) => channel.id)
        .toList(growable: false);

    final sorted = <String>[];
    for (final id in order) {
      if (normalized.remove(id)) {
        sorted.add(id);
      }
    }

    if (normalized.isNotEmpty) {
      final extra = normalized.toList(growable: false)..sort();
      sorted.addAll(extra);
    }

    return sorted;
  }

  String? _normalizeChannelId(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;
    for (final channel in companyMultipostingChannelCatalog) {
      if (channel.id == value) return value;
    }
    return null;
  }

  bool _isValidEmail(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(normalized);
  }

  @override
  Future<void> close() async {
    await _companyAuthSubscription.cancel();
    nameController.dispose();
    websiteController.dispose();
    industryController.dispose();
    teamSizeController.dispose();
    headquartersController.dispose();
    descriptionController.dispose();
    controllerLegalNameController.dispose();
    controllerTaxIdController.dispose();
    privacyContactEmailController.dispose();
    dpoNameController.dispose();
    dpoEmailController.dispose();
    privacyPolicyUrlController.dispose();
    retentionPolicySummaryController.dispose();
    internationalTransfersSummaryController.dispose();
    aiConsentTextVersionController.dispose();
    aiConsentTextController.dispose();
    return super.close();
  }
}
