import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/companies/models/company.dart';

enum CompanyProfileFormNotice { success, error }

class CompanyProfileFormState extends Equatable {
  const CompanyProfileFormState({
    this.company,
    this.avatarBytes,
    this.enabledMultipostingChannels = const [],
    this.hasChanges = false,
    this.canSubmit = false,
    this.isSaving = false,
    this.notice,
    this.noticeMessage,
  });

  final Company? company;
  final Uint8List? avatarBytes;
  final List<String> enabledMultipostingChannels;
  final bool hasChanges;
  final bool canSubmit;
  final bool isSaving;
  final CompanyProfileFormNotice? notice;
  final String? noticeMessage;

  @override
  List<Object?> get props => [
    company,
    avatarBytes,
    enabledMultipostingChannels,
    hasChanges,
    canSubmit,
    isSaving,
    notice,
    noticeMessage,
  ];

  CompanyProfileFormState copyWith({
    Company? company,
    Uint8List? avatarBytes,
    List<String>? enabledMultipostingChannels,
    bool? hasChanges,
    bool? canSubmit,
    bool? isSaving,
    CompanyProfileFormNotice? notice,
    String? noticeMessage,
    bool clearCompany = false,
    bool clearAvatarBytes = false,
    bool clearNotice = false,
  }) {
    return CompanyProfileFormState(
      company: clearCompany ? null : company ?? this.company,
      avatarBytes: clearAvatarBytes ? null : avatarBytes ?? this.avatarBytes,
      enabledMultipostingChannels:
          enabledMultipostingChannels ?? this.enabledMultipostingChannels,
      hasChanges: hasChanges ?? this.hasChanges,
      canSubmit: canSubmit ?? this.canSubmit,
      isSaving: isSaving ?? this.isSaving,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
    );
  }
}
