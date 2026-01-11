import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.uid,
    required this.role,
    this.avatarUrl,
    this.token,
    this.coverLetter,
    this.videoCurriculum,
  });

  final int id;
  final String name;
  final String lastName;
  final String email;
  final String uid;
  final String role;
  final String? avatarUrl;
  final String? token;
  final CandidateCoverLetter? coverLetter;
  final CandidateVideoCurriculum? videoCurriculum;

  factory Candidate.fromJson(Map<String, dynamic> json) {
    final rawCoverLetter = json['cover_letter'];
    final rawVideoCurriculum = json['video_curriculum'];
    return Candidate(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'candidate',
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
      'avatar_url': avatarUrl,
      'token': token,
      if (coverLetter != null) 'cover_letter': coverLetter!.toJson(),
      if (videoCurriculum != null) 'video_curriculum': videoCurriculum!.toJson(),
    };
  }

  Candidate copyWith({
    int? id,
    String? name,
    String? lastName,
    String? email,
    String? uid,
    String? role,
    String? avatarUrl,
    String? token,
    CandidateCoverLetter? coverLetter,
    CandidateVideoCurriculum? videoCurriculum,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      token: token ?? this.token,
      coverLetter: coverLetter ?? this.coverLetter,
      videoCurriculum: videoCurriculum ?? this.videoCurriculum,
    );
  }

  bool get hasCoverLetter => coverLetter?.text.trim().isNotEmpty == true;
  bool get hasVideoCurriculum =>
      videoCurriculum?.storagePath.trim().isNotEmpty == true;
}

class CandidateCoverLetter {
  const CandidateCoverLetter({required this.text, this.updatedAt});

  final String text;
  final DateTime? updatedAt;

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
}

class CandidateVideoCurriculum {
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
}

DateTime? _parseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
