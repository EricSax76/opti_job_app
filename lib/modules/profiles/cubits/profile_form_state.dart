import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:opti_job_app/modules/candidates/models/candidate.dart';

enum ProfileFormViewStatus { initial, loading, ready, empty, error }

enum ProfileFormNotice { success, error }

class ProfileFormState extends Equatable {
  const ProfileFormState({
    this.viewStatus = ProfileFormViewStatus.initial,
    this.candidateName = '',
    this.isSaving = false,
    this.avatarUrl,
    this.email = '',
    this.avatarBytes,
    this.hasChanges = false,
    this.errorMessage,
    this.canSubmit = false,
    this.notice,
    this.noticeMessage,
    this.onboardingProfile = _emptyOnboardingProfile,
    this.onboardingDraft = _emptyOnboardingProfile,
  });

  static const CandidateOnboardingProfile _emptyOnboardingProfile =
      CandidateOnboardingProfile(
        targetRole: '',
        preferredLocation: '',
        preferredModality: '',
        preferredSeniority: '',
        workStyleSkipped: true,
      );

  final ProfileFormViewStatus viewStatus;
  final String candidateName;
  final bool isSaving;
  final String? avatarUrl;
  final String email;
  final Uint8List? avatarBytes;
  final bool hasChanges;
  final String? errorMessage;
  final bool canSubmit;
  final ProfileFormNotice? notice;
  final String? noticeMessage;
  final CandidateOnboardingProfile onboardingProfile;
  final CandidateOnboardingProfile onboardingDraft;

  @override
  List<Object?> get props => [
    viewStatus,
    candidateName,
    isSaving,
    avatarUrl,
    email,
    avatarBytes,
    hasChanges,
    errorMessage,
    canSubmit,
    notice,
    noticeMessage,
    onboardingProfile,
    onboardingDraft,
  ];

  ProfileFormState copyWith({
    ProfileFormViewStatus? viewStatus,
    String? candidateName,
    bool? isSaving,
    String? avatarUrl,
    String? email,
    Uint8List? avatarBytes,
    bool? hasChanges,
    String? errorMessage,
    bool? canSubmit,
    ProfileFormNotice? notice,
    String? noticeMessage,
    CandidateOnboardingProfile? onboardingProfile,
    CandidateOnboardingProfile? onboardingDraft,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return ProfileFormState(
      viewStatus: viewStatus ?? this.viewStatus,
      candidateName: candidateName ?? this.candidateName,
      isSaving: isSaving ?? this.isSaving,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      hasChanges: hasChanges ?? this.hasChanges,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      canSubmit: canSubmit ?? this.canSubmit,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
      onboardingProfile: onboardingProfile ?? this.onboardingProfile,
      onboardingDraft: onboardingDraft ?? this.onboardingDraft,
    );
  }
}
