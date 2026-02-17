import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/cubits/company_auth_state.dart';
import 'package:opti_job_app/modules/companies/cubits/company_profile_form_state.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

class CompanyProfileFormCubit extends Cubit<CompanyProfileFormState> {
  CompanyProfileFormCubit({
    required ProfileRepository profileRepository,
    required CompanyAuthCubit companyAuthCubit,
  }) : _profileRepository = profileRepository,
       _companyAuthCubit = companyAuthCubit,
       nameController = TextEditingController(),
       super(const CompanyProfileFormState()) {
    nameController.addListener(_handleTextChanged);
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
  late final StreamSubscription<CompanyAuthState> _companyAuthSubscription;
  String _initialName = '';
  var _isSyncingControllerFromState = false;

  void clearNotice() {
    if (state.notice != null) {
      emit(state.copyWith(clearNotice: true));
    }
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
      emit(
        state.copyWith(
          avatarBytes: bytes,
          hasChanges: _computeHasChanges(
            name: nameController.text.trim(),
            avatarBytes: bytes,
          ),
          canSubmit: _canSubmit(
            hasChanges: _computeHasChanges(
              name: nameController.text.trim(),
              avatarBytes: bytes,
            ),
            isSaving: state.isSaving,
            name: nameController.text.trim(),
          ),
        ),
      );
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
    if (name.isEmpty || !state.canSubmit || !state.hasChanges) return;

    emit(state.copyWith(isSaving: true, canSubmit: false));
    try {
      final updatedCompany = await _profileRepository.updateCompanyProfile(
        uid: company.uid,
        name: name,
        avatarBytes: state.avatarBytes,
      );
      final mergedCompany = Company(
        id: updatedCompany.id,
        name: updatedCompany.name,
        email: updatedCompany.email,
        uid: updatedCompany.uid,
        role: updatedCompany.role,
        token: company.token,
        avatarUrl: updatedCompany.avatarUrl,
      );
      _companyAuthCubit.updateCompany(mergedCompany);
      _initialName = mergedCompany.name;
      _setNameControllerText(mergedCompany.name);
      emit(
        state.copyWith(
          company: mergedCompany,
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

    final name = nameController.text.trim();
    final hasChanges = _computeHasChanges(
      name: name,
      avatarBytes: state.avatarBytes,
    );
    final canSubmit = _canSubmit(
      hasChanges: hasChanges,
      isSaving: state.isSaving,
      name: name,
    );
    if (hasChanges != state.hasChanges || canSubmit != state.canSubmit) {
      emit(state.copyWith(hasChanges: hasChanges, canSubmit: canSubmit));
    }
  }

  bool _computeHasChanges({
    required String name,
    required Uint8List? avatarBytes,
  }) {
    final nameChanged = name != _initialName;
    final avatarChanged = avatarBytes != null;
    return nameChanged || avatarChanged;
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
      _initialName = '';
      _setNameControllerText('');
      emit(
        state.copyWith(
          clearCompany: true,
          clearAvatarBytes: true,
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

    _initialName = company.name;
    _setNameControllerText(company.name);
    emit(
      state.copyWith(
        company: company,
        clearAvatarBytes: true,
        hasChanges: false,
        canSubmit: false,
        isSaving: false,
        clearNotice: true,
      ),
    );
  }

  void _setNameControllerText(String value) {
    if (nameController.text == value) return;
    _isSyncingControllerFromState = true;
    nameController.value = nameController.value.copyWith(
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
        a.token == b.token &&
        a.avatarUrl == b.avatarUrl;
  }

  @override
  Future<void> close() async {
    await _companyAuthSubscription.cancel();
    nameController.dispose();
    return super.close();
  }
}
