import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:opti_job_app/modules/companies/cubits/company_auth_cubit.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';
import 'package:opti_job_app/modules/profiles/repositories/profile_repository.dart';

enum CompanyProfileFormNotice { success, error }

class CompanyProfileFormState extends Equatable {
  const CompanyProfileFormState({
    this.company,
    this.avatarBytes,
    this.hasChanges = false,
    this.canSubmit = false,
    this.isSaving = false,
    this.notice,
    this.noticeMessage,
  });

  final Company? company;
  final Uint8List? avatarBytes;
  final bool hasChanges;
  final bool canSubmit;
  final bool isSaving;
  final CompanyProfileFormNotice? notice;
  final String? noticeMessage;

  @override
  List<Object?> get props => [
        company,
        avatarBytes,
        hasChanges,
        canSubmit,
        isSaving,
        notice,
        noticeMessage,
      ];

  CompanyProfileFormState copyWith({
    Company? company,
    Uint8List? avatarBytes,
    bool? hasChanges,
    bool? canSubmit,
    bool? isSaving,
    CompanyProfileFormNotice? notice,
    String? noticeMessage,
    bool clearNotice = false,
  }) {
    return CompanyProfileFormState(
      company: company ?? this.company,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      hasChanges: hasChanges ?? this.hasChanges,
      canSubmit: canSubmit ?? this.canSubmit,
      isSaving: isSaving ?? this.isSaving,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
    );
  }
}

class CompanyProfileFormCubit extends Cubit<CompanyProfileFormState> {
  CompanyProfileFormCubit({
    required ProfileRepository profileRepository,
    required CompanyAuthCubit companyAuthCubit,
  })  : _profileRepository = profileRepository,
        _companyAuthCubit = companyAuthCubit,
        nameController = TextEditingController(),
        super(const CompanyProfileFormState()) {
    nameController.addListener(_handleTextChanged);
    final company = _companyAuthCubit.state.company;
    _initialName = company?.name ?? '';
    nameController.text = _initialName;
    emit(
      state.copyWith(
        company: company,
        hasChanges: false,
        canSubmit: false,
      ),
    );
  }

  final ProfileRepository _profileRepository;
  final CompanyAuthCubit _companyAuthCubit;
  final TextEditingController nameController;
  String _initialName = '';

  void clearNotice() {
    if (state.notice != null) {
      emit(state.copyWith(clearNotice: true));
    }
  }

  Future<void> pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
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
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('CompanyProfileFormCubit.pickAvatar error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
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
      nameController.text = mergedCompany.name;
      emit(
        state.copyWith(
          company: mergedCompany,
          avatarBytes: null,
          hasChanges: false,
          canSubmit: false,
          isSaving: false,
          notice: CompanyProfileFormNotice.success,
          noticeMessage: 'Perfil actualizado.',
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('CompanyProfileFormCubit.submit error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
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

  @override
  Future<void> close() {
    nameController.dispose();
    return super.close();
  }
}
