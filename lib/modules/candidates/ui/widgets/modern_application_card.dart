import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_offer_card_base.dart';

class ModernApplicationCard extends StatelessWidget {
  const ModernApplicationCard({
    super.key,
    required this.title,
    required this.company,
    this.description,
    this.avatarUrl,
    this.salary,
    this.location,
    this.modality,
    this.statusBadge,
    this.heroTag,
    required this.onTap,
  });

  final String title;
  final String company;
  final String? description;
  final String? avatarUrl;
  final String? salary;
  final String? location;
  final String? modality;
  final Widget? statusBadge;
  final Object? heroTag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CandidateOfferCardBase(
      title: title,
      company: company,
      description: description,
      avatarUrl: avatarUrl,
      salary: salary,
      location: location,
      modality: modality,
      heroTag: heroTag,
      heroTagPrefix: 'application_avatar',
      topRightBadge: statusBadge,
      onTap: onTap,
    );
  }
}
