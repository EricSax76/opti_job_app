import 'package:opti_job_app/core/utils/firestore_utils.dart';

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.uid,
    this.role = 'company',
    this.onboardingCompleted = false,
    this.token,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String email;
  final String uid;
  final String role;
  final bool onboardingCompleted;
  final String? token;
  final String? avatarUrl;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: FirestoreUtils.parseIntId(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'company',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      token: json['token'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'uid': uid,
      'role': role,
      'onboarding_completed': onboardingCompleted,
      'token': token,
      'avatar_url': avatarUrl,
    };
  }
}
