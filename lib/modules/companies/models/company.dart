import 'package:opti_job_app/core/utils/firestore_utils.dart';
import 'package:opti_job_app/modules/companies/models/company_compliance_profile.dart';
import 'package:opti_job_app/modules/companies/models/company_multiposting_settings.dart';

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.uid,
    this.role = 'company',
    this.onboardingCompleted = false,
    this.website = '',
    this.industry = '',
    this.teamSize = '',
    this.headquarters = '',
    this.description = '',
    this.multipostingSettings = const CompanyMultipostingSettings(),
    this.complianceProfile = const CompanyComplianceProfile(),
    this.token,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String email;
  final String uid;
  final String role;
  final bool onboardingCompleted;
  final String website;
  final String industry;
  final String teamSize;
  final String headquarters;
  final String description;
  final CompanyMultipostingSettings multipostingSettings;
  final CompanyComplianceProfile complianceProfile;
  final String? token;
  final String? avatarUrl;

  factory Company.fromJson(Map<String, dynamic> json) {
    final rawMultipostingSettings =
        json['multipostingChannelSettings'] ??
        json['multiposting_channel_settings'];
    final fallbackEnabledChannels =
        json['multipostingEnabledChannels'] ??
        json['multiposting_enabled_channels'];
    final rawComplianceSettings =
        json['complianceSettings'] ?? json['compliance_settings'];

    return Company(
      id: FirestoreUtils.parseIntId(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'company',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      website: (json['website'] ?? json['company_website'] ?? '')
          .toString()
          .trim(),
      industry: (json['industry'] ?? json['company_industry'] ?? '')
          .toString()
          .trim(),
      teamSize:
          (json['team_size'] ?? json['teamSize'] ?? json['company_size'] ?? '')
              .toString()
              .trim(),
      headquarters: (json['headquarters'] ?? json['hq_location'] ?? '')
          .toString()
          .trim(),
      description: (json['description'] ?? json['company_description'] ?? '')
          .toString()
          .trim(),
      multipostingSettings: CompanyMultipostingSettings.fromJson(
        rawMultipostingSettings,
        fallbackEnabledChannels: fallbackEnabledChannels,
      ),
      complianceProfile: CompanyComplianceProfile.fromJson(
        rawComplianceSettings,
      ),
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
      'website': website,
      'industry': industry,
      'team_size': teamSize,
      'headquarters': headquarters,
      'description': description,
      'multiposting_channel_settings': multipostingSettings.toJson(),
      'compliance_settings': complianceProfile.toJson(),
      'token': token,
      'avatar_url': avatarUrl,
    };
  }
}
