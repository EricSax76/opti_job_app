import 'package:flutter/material.dart';

import 'package:opti_job_app/modules/candidates/ui/widgets/candidate_offer_card_base.dart';

class ModernJobOfferCard extends StatelessWidget {
  const ModernJobOfferCard({
    super.key,
    required this.title,
    required this.company,
    this.avatarUrl,
    this.salary,
    this.location,
    this.modality,
    this.tags,
    this.heroTag,
    required this.onTap,
  });

  final String title;
  final String company;
  final String? avatarUrl;
  final String? salary;
  final String? location;
  final String? modality;
  final List<String>? tags;
  final Object? heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CandidateOfferCardBase(
      title: title,
      company: company,
      avatarUrl: avatarUrl,
      salary: salary,
      location: location,
      modality: modality,
      tags: tags,
      heroTag: heroTag,
      heroTagPrefix: 'job_offer_avatar',
      onTap: onTap,
    );
  }
}
