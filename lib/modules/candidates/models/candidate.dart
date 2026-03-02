import 'package:opti_job_app/core/utils/firestore_utils.dart';
import 'package:equatable/equatable.dart';

class Candidate extends Equatable {
  const Candidate({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.uid,
    required this.role,
    this.onboardingCompleted = false,
    this.onboardingProfile,
    this.avatarUrl,
    this.token,
    this.coverLetter,
    this.videoCurriculum,
  });

  // Note: Using int for ID, but if Firestore auto-generated alphanumeric IDs
  // are expected in the future, this should be refactored to String.
  // Currently, FirestoreUtils.parseIntId handles string-numbers, but defaults to 0 for alphanumerics.
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String uid;
  final String role;
  final bool onboardingCompleted;
  final CandidateOnboardingProfile? onboardingProfile;
  final String? avatarUrl;
  final String? token;
  final CandidateCoverLetter? coverLetter;
  final CandidateVideoCurriculum? videoCurriculum;

  @override
  List<Object?> get props => [
        id,
        name,
        lastName,
        email,
        uid,
        role,
        onboardingCompleted,
        onboardingProfile,
        avatarUrl,
        token,
        coverLetter,
        videoCurriculum,
      ];

  @override
  bool get stringify => true;

  factory Candidate.fromJson(Map<String, dynamic> json) {
    final rawCoverLetter = json['cover_letter'];
    final rawVideoCurriculum = json['video_curriculum'];
    final rawOnboardingProfile = json['onboarding_profile'];
    
    return Candidate(
      id: FirestoreUtils.parseIntId(json['id']),
      name: json['name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'candidate',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      onboardingProfile: rawOnboardingProfile is Map<String, dynamic>
          ? CandidateOnboardingProfile.fromJson(rawOnboardingProfile)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      token: json['token'] as String?,
      coverLetter: rawCoverLetter is Map<String, dynamic>
          ? CandidateCoverLetter.fromJson(rawCoverLetter)
          : null,
      videoCurriculum: rawVideoCurriculum is Map<String, dynamic>
          ? CandidateVideoCurriculum.fromJson(rawVideoCurriculum)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'uid': uid,
      'role': role,
      'onboarding_completed': onboardingCompleted,
      if (onboardingProfile != null)
        'onboarding_profile': onboardingProfile!.toJson(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (token != null) 'token': token,
      if (coverLetter != null) 'cover_letter': coverLetter!.toJson(),
      if (videoCurriculum != null)
        'video_curriculum': videoCurriculum!.toJson(),
    };
  }

  Candidate copyWith({
    int? id,
    String? name,
    String? lastName,
    String? email,
    String? uid,
    String? role,
    bool? onboardingCompleted,
    CandidateOnboardingProfile? onboardingProfile,
    String? avatarUrl,
    String? token,
    CandidateCoverLetter? coverLetter,
    CandidateVideoCurriculum? videoCurriculum,
    bool clearOnboardingProfile = false,
    bool clearAvatarUrl = false,
    bool clearToken = false,
    bool clearCoverLetter = false,
    bool clearVideoCurriculum = false,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingProfile: clearOnboardingProfile
          ? null
          : (onboardingProfile ?? this.onboardingProfile),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      token: clearToken ? null : (token ?? this.token),
      coverLetter: clearCoverLetter ? null : (coverLetter ?? this.coverLetter),
      videoCurriculum: clearVideoCurriculum
          ? null
          : (videoCurriculum ?? this.videoCurriculum),
    );
  }

  bool get hasCoverLetter => coverLetter?.text.trim().isNotEmpty == true;
  bool get hasVideoCurriculum =>
      videoCurriculum?.storagePath.trim().isNotEmpty == true;
}

class CandidateOnboardingProfile extends Equatable {
  const CandidateOnboardingProfile({
    required this.targetRole,
    required this.preferredLocation,
    required this.preferredModality,
    required this.preferredSeniority,
    required this.workStyleSkipped,
    this.startOfDayPreference,
    this.feedbackPreference,
    this.structurePreference,
    this.taskPacePreference,
  });

  final String targetRole;
  final String preferredLocation;
  final String preferredModality;
  final String preferredSeniority;
  final bool workStyleSkipped;
  final String? startOfDayPreference;
  final String? feedbackPreference;
  final String? structurePreference;
  final String? taskPacePreference;

  @override
  List<Object?> get props => [
        targetRole,
        preferredLocation,
        preferredModality,
        preferredSeniority,
        workStyleSkipped,
        startOfDayPreference,
        feedbackPreference,
        structurePreference,
        taskPacePreference,
      ];

  @override
  bool get stringify => true;

  factory CandidateOnboardingProfile.fromJson(Map<String, dynamic> json) {
    return CandidateOnboardingProfile(
      targetRole: json['target_role'] as String? ?? '',
      preferredLocation: json['preferred_location'] as String? ?? '',
      preferredModality: json['preferred_modality'] as String? ?? '',
      preferredSeniority: json['preferred_seniority'] as String? ?? '',
      workStyleSkipped: json['work_style_skipped'] as bool? ?? false,
      startOfDayPreference: json['start_of_day_preference'] as String?,
      feedbackPreference: json['feedback_preference'] as String?,
      structurePreference: json['structure_preference'] as String?,
      taskPacePreference: json['task_pace_preference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_role': targetRole,
      'preferred_location': preferredLocation,
      'preferred_modality': preferredModality,
      'preferred_seniority': preferredSeniority,
      'work_style_skipped': workStyleSkipped,
      if (startOfDayPreference != null)
        'start_of_day_preference': startOfDayPreference,
      if (feedbackPreference != null)
        'feedback_preference': feedbackPreference,
      if (structurePreference != null)
        'structure_preference': structurePreference,
      if (taskPacePreference != null)
        'task_pace_preference': taskPacePreference,
    };
  }

  CandidateOnboardingProfile copyWith({
    String? targetRole,
    String? preferredLocation,
    String? preferredModality,
    String? preferredSeniority,
    bool? workStyleSkipped,
    String? startOfDayPreference,
    String? feedbackPreference,
    String? structurePreference,
    String? taskPacePreference,
    bool clearStartOfDayPreference = false,
    bool clearFeedbackPreference = false,
    bool clearStructurePreference = false,
    bool clearTaskPacePreference = false,
  }) {
    return CandidateOnboardingProfile(
      targetRole: targetRole ?? this.targetRole,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      preferredModality: preferredModality ?? this.preferredModality,
      preferredSeniority: preferredSeniority ?? this.preferredSeniority,
      workStyleSkipped: workStyleSkipped ?? this.workStyleSkipped,
      startOfDayPreference: clearStartOfDayPreference
          ? null
          : (startOfDayPreference ?? this.startOfDayPreference),
      feedbackPreference: clearFeedbackPreference
          ? null
          : (feedbackPreference ?? this.feedbackPreference),
      structurePreference: clearStructurePreference
          ? null
          : (structurePreference ?? this.structurePreference),
      taskPacePreference: clearTaskPacePreference
          ? null
          : (taskPacePreference ?? this.taskPacePreference),
    );
  }
}

class CandidateCoverLetter extends Equatable {
  const CandidateCoverLetter({required this.text, this.updatedAt});

  final String text;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [text, updatedAt];

  @override
  bool get stringify => true;

  factory CandidateCoverLetter.fromJson(Map<String, dynamic> json) {
    return CandidateCoverLetter(
      text: json['text'] as String? ?? '',
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CandidateCoverLetter copyWith({
    String? text,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return CandidateCoverLetter(
      text: text ?? this.text,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }
}

class CandidateVideoCurriculum extends Equatable {
  const CandidateVideoCurriculum({
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    this.updatedAt,
  });

  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [storagePath, contentType, sizeBytes, updatedAt];

  @override
  bool get stringify => true;

  factory CandidateVideoCurriculum.fromJson(Map<String, dynamic> json) {
    return CandidateVideoCurriculum(
      storagePath: json['storage_path'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storage_path': storagePath,
      'content_type': contentType,
      'size_bytes': sizeBytes,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CandidateVideoCurriculum copyWith({
    String? storagePath,
    String? contentType,
    int? sizeBytes,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return CandidateVideoCurriculum(
      storagePath: storagePath ?? this.storagePath,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    );
  }
}

DateTime? _parseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
